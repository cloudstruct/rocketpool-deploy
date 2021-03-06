#!/bin/bash

export AWS_DEFAULT_REGION=${aws_vars.region}

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

%{if eip_id != "false" }

EIP_ALLOCATION_ID=${eip_id}

(
set -x

aws ec2 associate-address --instance-id $${INSTANCE_ID} --allocation-id $${EIP_ALLOCATION_ID} --allow-reassociation
)

%{endif}

VOLUME_ID=${ebs_volume_id}
NVME_DEVICE=nvme1n1
MOUNT_DIR=/data

(
set -x
END=0
until [ "$END" -eq 1 ]
do
  ATTACHED_INSTANCE=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" | jq -r '.Volumes[] | .Attachments[].InstanceId' | sort -u)
  echo "INFO: Attached instance: $${ATTACHED_INSTANCE}"
  aws ec2 attach-volume --volume-id "$VOLUME_ID" --instance-id "$INSTANCE_ID" --device /dev/sdf
  if [[ "$?" == 0 ]]; then
    END=1
  elif [[ "$ATTACHED_INSTANCE" == "$INSTANCE_ID" ]]; then
    END=1
  fi
done
)

# Wait for device to show up
while true; do
  [[ -e /sys/block/$${NVME_DEVICE} ]] && break
  sleep 1
done

set -x

# Check for existing filesystem, and format if none found
if ! dumpe2fs /dev/$${NVME_DEVICE} >& /dev/null; then
  mkfs.ext4 /dev/$${NVME_DEVICE}
fi

mkdir -p $${MOUNT_DIR}

echo "/dev/$${NVME_DEVICE}  /data  ext4  noatime  0  0" >> /etc/fstab

mount $${MOUNT_DIR}

# Start Ansible code
apt-get -y install python3-venv
python3 -m venv /root/.venv
. /root/.venv/bin/activate
/root/.venv/bin/python -m pip -q --no-input install --upgrade pip
/root/.venv/bin/pip -q --no-input install awscli
mkdir /root/cloudstruct-rocketpool-deploy
aws s3 cp s3://${s3_deploy_bucket}/ansible-${rocketpool_version}.tar.gz /root/ansible-${rocketpool_version}.tar.gz
tar -zxf /root/ansible-${rocketpool_version}.tar.gz -C /root/cloudstruct-rocketpool-deploy
pushd /root/cloudstruct-rocketpool-deploy
/root/.venv/bin/pip -q --no-input install -r requirements.txt
pushd /root/cloudstruct-rocketpool-deploy/ansible
/root/.venv/bin/ansible-galaxy install -r requirements.yml -f
/root/.venv/bin/ansible-playbook site.yml -e "POOL=${rocketpool_pool}"
popd
popd
