# CloudStruct Rocketpool Terraform and Ansible
Automation to deploy/manage a Rocketpool Ethereum staking pool node

## Known limitations
- This is in early alpha and not a proven setup yet.
- Currently only built for AWS
- Currently only supports Prsym as ETH2 validator

## Pre-requisites
- An AWS Account and AWS Access & Secret key credentials setup and ready to use
- An ubuntu CLI which has python3, python3-pip, and python3-venv installed.

## Install notes
```
scripts/quick-install.sh
```

### Obtain Private SSH Key
If you set the config to generate an SSH key for you via AWS then you can use the following command to retrieve this key from the encrypted s3 bucket.
`terraform output -json | jq '.ssh_private_key.value' -r`

## What does it do?
- Performs environment checks/pre-execution validation
- Creates a python3 virtual environment and installs required software
- Runs the terraform bootstrap to setup object storage for state file and dynamodb for state locking
- Runs the terraform to setup rocketpool
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
