#!/usr/bin/env bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
FORCE_INSTALL=0
SYS_SETUP=0
POOL_NAME="mainnet-00"
SKIP_TAGS_ARG=""

usage()
{
cat << EOF
usage: bash ./scripts/local-ansible-install.sh -s
-h    | --help         Brings up this menu
-e    | --exclude      Comma separated value of actions to exclude.
                       Current options: ['firewall','reboot','rocketpool','security','ssh']
-p    | --pool         Specify pool name.  Defaults to mainnet-00
-r    | --reinstall    By default this script will not re-install local workstation packages.  Set this to override that.
-s    | --system-setup This flag requires sudo privileges.  It installs python3-venv and all dependencies on the system.
EOF
}

while [ "$1" != "" ]; do
    case $1 in
        -h | --help )    usage
            exit 0
        ;;
        -e | --exclude )
            shift
            SKIP_TAGS="$1"
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
        -s | --system-setup )
            SYS_SETUP=1
        ;;
        * )              usage
            exit 1
        ;;
    esac
    shift
done

# Install virtual environment to execute ansible
if [[ "$SYS_SETUP" == 1 ]]; then
  sudo apt-get -y install python3-venv
  if [[ ! -e ${HOME}/.venv/cloudstruct-rocketpool ]]; then
    python3 -m venv ${HOME}/.venv/cloudstruct-rocketpool
  fi
fi

# Set SKIP_TAGS_ARG
if [[ ! -z "$SKIP_TAGS" ]]; then
  SKIP_TAGS_ARG="--skip-tags '${SKIP_TAGS}'"
fi

# Activate Virtual Environment
if [[ -f ${HOME}/.venv/cloudstruct-rocketpool/bin/activate ]]; then
  . ${HOME}/.venv/cloudstruct-rocketpool/bin/activate
else
  echo "ERROR: Virtual environment directory not found."
  exit 1
fi

if [[ "$FORCE_INSTALL" == 1 || ! -e ${HOME}/.venv/cloudstruct-rocketpool ]]; then
  python -m pip -q --no-input install --upgrade pip
  pip -q --no-input install -r requirements.txt
  pushd ${SCRIPT_DIR}/../ansible
  ansible-galaxy install -r requirements.yml
  popd
fi

pushd ${SCRIPT_DIR}/../ansible
ansible-playbook site.yml -e "POOL=${POOL_NAME}" "$SKIP_TAGS_ARG"
popd

echo "INFO: Ansible run completed successfully."
exit 0
