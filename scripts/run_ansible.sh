#!/bin/bash

POOL=
EXTRA_ANSIBLE_ARGS=()

while [[ $# -gt 0 ]]; do
	case $1 in
		-p|--pool)
			POOL=$2
			shift 2
			;;
		--)
			shift
			EXTRA_ANSIBLE_ARGS+=( $@ )
			break
			;;
		--*)
			echo "Unrecognized option: $1"
			exit 1
			;;
		*)
			echo "Unrecognized argument: $1"
			exit 1
			;;
	esac
done

if [[ -z ${POOL} ]]; then
	echo "You must specify the --pool option"
	exit 1
fi

BASEDIR=$(cd $(dirname $0)/..; pwd -P)

cd ${BASEDIR}/ansible

ansible-playbook \
	-i hosts.aws_ec2.yml \
	--limit cardano_pool_${POOL//-/_} \
	-e @${BASEDIR}/vars/pools/${POOL}/node.yaml \
	node.yml \
	${EXTRA_ANSIBLE_ARGS[@]}
