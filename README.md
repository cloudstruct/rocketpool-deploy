# CloudStruct Rocketpool Terraform and Ansible
Automation to deploy/manage a Rocketpool Ethereum staking pool node

## Known limitations
- This is in early alpha and not a proven setup yet.
- Currently only built for AWS
- Currently only supports Prsym as ETH2 validator

## Pre-requisites
- An AWS Account and AWS Access & Secret key credentials
- A linux workstation with required software installed (See Install Notes below)

## Install notes
```
python3 -m venv ~/.cloudstruct
. ~/.cloudstruct/bin/activate
./scripts/setup_virtualenv.sh
cd terraform
terraform workspace create mainnet-01
```

## What does it do?
- terraform takes information from configured yaml and:
- create AWS VPC, subnets, route tables, etc. etc.
- creates a deployment s3 bucket
- bundles the ansible required code and puts it in s3 .tar.gz
- creates iam roles for rocketpool node ec2 instance to use (re-attach EBS, re-attach EIP, use deployment s3 bucket) as instance profile
- creates single-instance ASG with launch template for self-healing.
- Add user-data to launch-template to download ansible code from s3 and run at first-boot
- ansible will security harden instance, update packages, and install rocketpool (reboot if required)
- add cloudwatch alarms (slack alerts exist, email alerts coming soon) to the ASG+EC2 instance
- Create required security groups and lock down SSH+Grafana to ip-whitelist including option to dyamically add IP of executing workstation
- Installs rocketpool and node-exporter grafana dashboards

# Credit
- @tedsteen https://github.com/tedsteen/rocketpool for ansible galaxy and role inspiration
- @cloudstruct team for initial terraform code and layout
