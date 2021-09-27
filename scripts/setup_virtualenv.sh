#!/bin/bash
##############################
#
# Example: ./scripts/setup_virtualenv.sh
# Purpose: Quickly install or update required tooling into an activated virtualenv 
#
##############################

if [[ -z $VIRTUAL_ENV ]]; then
  echo "ERROR: Must have a python virtualenv activated."
  exit 1
fi

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
export TOOLS_YAML="${REPO_DIR}/vars/tools.yaml"

installYQ (){
  # Grab YQ version
  YQ_VERSION=$(egrep "^yq:$" vars/tools.yaml -A2 | grep "version" | awk '{print $2}')
  YQ_URL=$(egrep "^yq:$" vars/tools.yaml -A2 | grep "url" | awk '{ print $2}')
  wget ${YQ_URL/VERSION/${YQ_VERSION}} -O ${VIRTUAL_ENV}/bin/yq
  chmod +x ${VIRTUAL_ENV}/bin/yq
}

getUrls (){
  HELM_VERSION=$(yq -e e '.helm.version' ${TOOLS_YAML})
  HELMFILE_VERSION=$(yq -e e '.helmfile.version' ${TOOLS_YAML})
  KUBECTL_VERSION=$(yq -e e '.kubectl.version' ${TOOLS_YAML})
  TERRAFORM_VERSION=$(yq -e e '.terraform.version' ${TOOLS_YAML})

  HELM_URL=$(yq -e e '.helm.url |= sub("VERSION", "'${HELM_VERSION}'") | .helm.url' ${TOOLS_YAML})
  HELMFILE_URL=$(yq -e e '.helmfile.url |= sub("VERSION", "'${HELMFILE_VERSION}'") | .helmfile.url' ${TOOLS_YAML})
  KUBECTL_URL=$(yq -e e '.kubectl.url |= sub("VERSION", "'${KUBECTL_VERSION}'") | .kubectl.url' ${TOOLS_YAML})
  TERRAFORM_URL=$(yq -e e '.terraform.url |= sub("VERSION", "'${TERRAFORM_VERSION}'") | .terraform.url' ${TOOLS_YAML})
}

printDesiredVersions (){
  echo "INFO: Updating to the following versions in ${VIRTUAL_ENV}/bin/"
  echo "  - HELM: ${HELM_VERSION}"
  echo "  - HELMFILE: ${HELMFILE_VERSION}"
  echo "  - TERRAFORM: ${TERRAFORM_VERSION}"
  echo "  - KUBECTL: ${KUBECTL_VERSION}"
  echo "  - YQ: $(yq -e e '.yq.version' ${TOOLS_YAML})"
}

installKubectl (){
  echo "INFO: Installing kubectl version ${KUBECTL_VERSION}..."
  KUBECTL_CURRENT=$(kubectl version --short --client -o json | jq '.clientVersion.gitVersion' -r 2>/dev/null)
  if [[ "$KUBECTL_CURRENT" != "v${KUBECTL_VERSION}" ]]; then
    echo "INFO: Grabbing kubectl from ${KUBECTL_URL}..."
    wget -q "${KUBECTL_URL}" -O ${VIRTUAL_ENV}/bin/kubectl
    chmod +x ${VIRTUAL_ENV}/bin/kubectl
  else
    echo "INFO: Kubectl version match, skipping..."
  fi
}

installHelm (){
  echo "INFO: Installing helm version ${HELM_VERSION}..."
  HELM_CURRENT=$(helm version --short --template '{{ .Version }}' 2>/dev/null)
  if [[ "$HELM_CURRENT" != "v${HELM_VERSION}" ]]; then
    echo "INFO: Grabbing helm file ${HELM_URL}..."
    wget -q ${HELM_URL} -O helm-v${HELM_VERSION}-linux-amd64.tar.gz
    tar -zxf helm-v${HELM_VERSION}-linux-amd64.tar.gz
    mv linux-amd64/helm ${VIRTUAL_ENV}/bin/helm
    chmod +x ${VIRTUAL_ENV}/bin/helm
    rm -rf helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64
    # Helm Plugins
    echo "INFO: Installing helm plugin helm-diff..."
    ${VIRTUAL_ENV}/bin/helm plugin install https://github.com/databus23/helm-diff
  else
    echo "INFO: Helm version match, skipping..."
  fi
}

installHelmfile (){
  echo "INFO: Installing helmfile version ${HELMFILE_VERSION}..."
  HELMFILE_CURRENT=$(helmfile version | awk '{ print $3 }' 2>/dev/null)
  if [[ "$HELMFILE_CURRENT" != "v${HELMFILE_VERSION}" ]]; then
    echo "INFO: Grabbing helm file ${HELMFILE_URL}..."
    wget -q ${HELMFILE_URL} -O ${VIRTUAL_ENV}/bin/helmfile
    chmod +x ${VIRTUAL_ENV}/bin/helmfile
  else
    echo "INFO: Helmfile version match, skipping..."
  fi
}

installTerraform (){
  echo "INFO: Installing terraform version ${TERRAFORM_VERSION}..."
  TERRAFORM_CURRENT=$(terraform version -json | jq '.terraform_version' -r 2>/dev/null)
  if [[ "$TERRAFORM_CURRENT" != "${TERRAFORM_VERSION}" ]]; then
    echo "INFO: Grabbing helm file ${TERRAFORM_URL}..."
    wget -q ${TERRAFORM_URL} -O terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d ${VIRTUAL_ENV}/bin
    chmod +x ${VIRTUAL_ENV}/bin/terraform
    rm -rf terraform_${TERRAFORM_VERSION}_linux_amd64.zip
  else
    echo "INFO: Terraform version match, skipping..."
  fi
}

installPythonRequirements (){
  echo "INFO: Installing Python packages..."
  pip -q install -r ${REPO_DIR}/requirements.txt -U
}

printVersions (){
  echo "INFO: terraform version ${VIRTUAL_ENV}/bin/terraform"
  ${VIRTUAL_ENV}/bin/terraform version

  echo "INFO: helm version ${VIRTUAL_ENV}/bin/helm"
  ${VIRTUAL_ENV}/bin/helm version

  echo "INFO: helmfile version ${VIRTUAL_ENV}/bin/helmfile"
  ${VIRTUAL_ENV}/bin/helmfile version
  
  echo "INFO: kubectl version ${VIRTUAL_ENV}/bin/kubectl"
  ${VIRTUAL_ENV}/bin/kubectl version --client=true
}

HELM_VERSION=""
HELMFILE_VERSION=""
KUBECTL_VERSION=""
TERRAFORM_VERSION=""
HELM_URL=""
HELMFILE_URL=""
KUBECTL_URL=""
TERRAFORM_URL=""

getYQ
getUrls
printDesiredVersions
installKubectl
installHelm
installHelmfile
installTerraform
installPythonRequirements
printVersions

exit 0
