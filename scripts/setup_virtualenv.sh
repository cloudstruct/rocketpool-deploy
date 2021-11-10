#!/bin/bash
##############################
#
# Example: ./scripts/setup_virtualenv.sh
# Purpose: Quickly install or update required tooling into an activated virtualenv 
#
##############################
set -e

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
export TOOLS_YAML="${REPO_DIR}/vars/tools.yaml"
export TOOLS_ARCH=$(uname -i)

if [[ "$TOOLS_ARCH" == "x86_64" ]]; then
  export TOOLS_ARCH="amd64"
elif [[ "$TOOLS_ARCH" == "aarch64" ]]; then
  export TOOLS_ARCH="arm64"
else
  echo "ERROR: Hardware architecture not supported."
  exit 1
fi
 
# User can specify virtualenv path
VIRTUAL_ENV_PATH="${1:-~/.virtualenvs/cloudstruct-rocketpool}"
TMPDIR=$(mktemp -d /tmp/rocketpooltmp-XXXXXXX) || { echo "Failed to create temp file"; exit 1; }

installYQ (){
  # Grab YQ version
  YQ_VERSION=$(egrep "^yq:$" vars/tools.yaml -A2 | grep "version" | awk '{print $2}')
  YQ_URL=$(egrep "^yq:$" vars/tools.yaml -A2 | grep "url" | awk '{ print $2}')
  YQ_URL_VERSION="${YQ_URL/VERSION/${YQ_VERSION}}"
  YQ_URL_ARCH="${YQ_URL_VERSION/ARCH/${TOOLS_ARCH}}"
  wget -q "$YQ_URL_ARCH" -O "${VIRTUAL_ENV_PATH}/bin/yq"
  chmod +x ${VIRTUAL_ENV_PATH}/bin/yq
}

getUrls (){
  TERRAFORM_VERSION=$(yq -e e '.terraform.version' ${TOOLS_YAML})
  TERRAFORM_URL=$(yq -e e '.terraform.url |= sub("VERSION", "'${TERRAFORM_VERSION}'") | .terraform.url' ${TOOLS_YAML})
}

printDesiredVersions (){
  echo "INFO: Updating to the following versions in ${VIRTUAL_ENV_PATH}/bin/"
  echo "  - TERRAFORM: ${TERRAFORM_VERSION}"
  echo "  - YQ: $(yq -e e '.yq.version' ${TOOLS_YAML})"
}

installTerraform (){
  echo "INFO: Installing terraform version ${TERRAFORM_VERSION}..."
  TERRAFORM_CURRENT=$(terraform version -json | jq '.terraform_version' -r 2>/dev/null)
  if [[ "$TERRAFORM_CURRENT" != "${TERRAFORM_VERSION}" ]]; then
    echo "INFO: Grabbing terraform from ${TERRAFORM_URL}..."
    wget -q "${TERRAFORM_URL}" -O "${TMPDIR}/terraform_${TERRAFORM_VERSION}_linux_${TOOLS_ARCH}.zip"
    unzip "${TMPDIR}/terraform_${TERRAFORM_VERSION}_linux_${TOOLS_ARCH}.zip" -d "${VIRTUAL_ENV_PATH}/bin"
    chmod +x "${VIRTUAL_ENV_PATH}/bin/terraform"
    rm -rf "${TMPDIR}"
  else
    echo "INFO: Terraform version match, skipping..."
  fi
}

installPythonRequirements (){
  echo "INFO: Installing Python packages..."
  ${VIRTUAL_ENV_PATH}/bin/pip -q install -r ${REPO_DIR}/requirements.txt -U
}

printVersions (){
  echo "INFO: terraform version ${VIRTUAL_ENV_PATH}/bin/terraform"
  ${VIRTUAL_ENV_PATH}/bin/terraform version
}

TERRAFORM_VERSION=""
TERRAFORM_URL=""

/usr/bin/env python3 -m venv "$VIRTUAL_ENV_PATH"
. "$VIRTUAL_ENV_PATH/bin/activate"

installYQ
getUrls
printDesiredVersions
installTerraform
installPythonRequirements
printVersions

exit 0
