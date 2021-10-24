#!/usr/bin/env bash

# This script is designed to help someone bootstrap terraform and requires the
# user already has AWS credentials and Terraform installed

check_prerequisites() {
  aws sts get-caller-identity 2>&1 >/dev/null
  if [[ $? -ne 0 ]]; then
    echo "You must configure your local 'aws' client before using this tool"
    exit 1
  fi

  local __tfver=$(terraform version | sed 's/^.* v//' 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    echo "You must install Terraform."
    exit 1
  fi
  return 0
}

check_prerequisites

set -e
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd ${SCRIPT_DIR}/../terraform/bootstrap
terraform init
terraform validate
terraform plan -detailed-exitcode -input=false
case $? in
  2) terraform apply ;;
  *) exit $? ;;
esac
