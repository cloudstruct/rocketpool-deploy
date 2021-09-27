#!/bin/bash

export AWS_DEFAULT_REGION=${aws_vars.region}

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

%{if lookup(node_value, "eip", false)}

EIP_ALLOCATION_ID=${eip_id[node_key]}

(
set -x

aws ec2 associate-address --instance-id $${INSTANCE_ID} --allocation-id $${EIP_ALLOCATION_ID} --allow-reassociation
)

%{endif}

VOLUME_ID=${ebs_volume_id[node_key]}
NVME_DEVICE=nvme1n1
MOUNT_DIR=/data

(
set -x
aws ec2 attach-volume --volume-id $${VOLUME_ID} --instance-id $${INSTANCE_ID} --device /dev/sdf
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
