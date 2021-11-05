#!/usr/bin/env bash
# This script is designed to help someone bootstrap terraform and requires the
# user already has AWS credentials configured

check_prerequisites() {
    set -e
    aws sts get-caller-identity 2>&1 >/dev/null
    if [[ $? -ne 0 ]]; then
        echo "You must configure your local 'aws' client before using this tool"
        exit 1
    fi

    if [[ ! -e "$VIRTUAL_ENV_PATH" || $FORCE_INSTALL -gt 0 ]]; then
        echo "INFO: Installing into path ${VIRTUAL_ENV_PATH}"
        bash "${SCRIPT_DIR}/setup_virtualenv.sh" "$VIRTUAL_ENV_PATH"
    fi

    . "${VIRTUAL_ENV_PATH}/bin/activate"

    local __tfver=$(terraform version | sed 's/^.* v//' 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "You must install Terraform."
        exit 1
    fi

    return 0
}

usage()
{
cat << EOF
usage: bash ./scripts/quick-install.sh -a -y
-a    | --apply      This flag is required to deploy rocketpool.  Default action is 'plan'.
-d    | --dir        This sets the local workstation virtualenv install directory.
                     Default is '${HOME}/.virtualenvs/cloudstruct-rocketpool'
-h    | --help       Brings up this menu
-p    | --pool       Specify pool name.  Defaults to mainnet-00
-r    | --reinstall  By default this script will not re-install local workstation packages.  Set this to override that.
-y    | --yes        This answers 'yes' to all prompts automatically.
                     Without this flag manual acceptance/response is required during deployment.
EOF
}

tfrun()
{
    terraform init
    terraform workspace select default
    terraform workspace new ${POOL_NAME} || true
    terraform workspace select ${POOL_NAME}
    terraform workspace list
    terraform validate
    terraform plan
    if [[ "$TERRAFORM_CMD" == "apply" ]]; then
        terraform apply ${1}
    fi
}

FORCE_INSTALL=0
TERRAFORM_CMD="plan"
AUTO_APPROVE=""
VIRTUAL_ENV_PATH="${HOME}/.virtualenvs/cloudstruct-rocketpool"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

while [ "$1" != "" ]; do
    case $1 in
        -a | --apply )
            TERRAFORM_CMD="apply"
        ;;
        -d | --dir )
            shift
            VIRTUAL_ENV_PATH="$1"
            if [[ -f  "$VIRTUAL_ENV_PATH" ]]; then
               echo "ERROR: File already exists at local install directory."
               exit 1
            fi
        ;;
        -h | --help )    usage
            exit 0
        ;;
        -p | --pool )
            shift
            POOL_NAME="$1"
            if [[ ! -d "${SCRIPT_DIR}/../vars/pools/${POOL_NAME}" ]]; then
              echo "ERROR: Config directory '${SCRIPT_DIR}/../vars/pools/${POOL_NAME}' is not found."
              exit 1
            fi
        ;;
        -r | --reinstall )
            FORCE_INSTALL=1
        ;;
        -y | --yes )
            AUTO_APPROVE="--auto-approve"
        ;;
        * )              usage
            exit 1
        ;;
    esac
    shift
done

check_prerequisites

pushd ${SCRIPT_DIR}/../terraform/bootstrap
tfrun "$AUTO_APPROVE"
popd
echo "INFO: Terraform bootstrap execution successful."

pushd ${SCRIPT_DIR}/../terraform/rocketpool
tfrun "$AUTO_APPROVE"
popd
echo "INFO: Terraform rocketpool execution successful."

exit 0
