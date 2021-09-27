#!/bin/bash

set -eo pipefail

TERRAFORM_VERSION=1.0.7
TERRAFORM_IMAGE=hashicorp/terraform:${TERRAFORM_VERSION}

BASEDIR=$(cd $(dirname $0)/.. && pwd -P)

cd ${BASEDIR}/terraform

CURDIR=$(pwd -P)
SUBDIR=$(echo "${CURDIR}" | sed -e "s|^${BASEDIR}/||")

docker run \
	-ti --rm \
	-v ${HOME}/.aws:/root/.aws:ro \
	-v ${BASEDIR}:/code \
	-w /code/${SUBDIR} \
	--env-file <(env | grep ^AWS_ | sort) \
	${TERRAFORM_IMAGE} \
	"$@"
