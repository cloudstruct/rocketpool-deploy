#!/usr/bin/env bash
set -eo pipefail

# Global Variables
TERRAFORM_VERSION=1.0.8
TERRAFORM_IMAGE=hashicorp/terraform:${TERRAFORM_VERSION}
BASEDIR=$(cd $(dirname $0)/.. && pwd -P)

HELP="\
Usage:
  $0 plan
  $0 apply
  $0
pushd "${BASEDIR}/terraform/"

CURDIR=$(pwd -P)
SUBDIR=$(echo "${CURDIR}" | sed -e "s|^${BASEDIR}/||")

if [ -x "$(command -v docker)" ]; then
  docker run \
    -ti --rm \
    -v ${HOME}/.aws:/root/.aws:ro \
    -v ${BASEDIR}:/code \
    -w /code/${SUBDIR} \
    --env-file <(env | grep ^AWS_ | sort) \
    ${TERRAFORM_IMAGE} \
    "$@"
else
  terraform "$@"

popd
