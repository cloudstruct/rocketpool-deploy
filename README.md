# CloudStruct Rocketpool Terraform and Ansible
Automation to deploy/manage a Rocketpool Ethereum staking pool node

## Why?
You may be asking why does this repo exist?  Rocketpool already has a fantastic install guide, docker containers, docker-compose setup, etc.
The reasons someone might want to use this repo are:
* Production level deployment (Things like uptime, self-healing, monitoring, notifications for monitoring, and repeatability)
* You do not want to put the effort in to doing it manually.
* You do not want to concern yourself with constantly maintaining and updating your node
* You would like to leverage the experience and knowledge of a company filled with experts doing DevOps As A Service (CloudStruct)

## Known limitations
- Currently only built for AWS
- Currently only supports Prsym as ETH2 validator

## Pre-requisites
- An AWS Account and AWS Access & Secret key credentials setup and ready to use
- An ubuntu CLI which has python3, python3-pip, and python3-venv installed.

## Pre-Install Notes
Take a look at and edit the following files as desired. The comments should provide context.
- [vars/defaults.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/defaults.yaml)
- [vars/pools/mainnet-00/aws.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/aws.yaml)
- [vars/pools/mainnet-00/node.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/node.yaml)
- [vars/pools/mainnet-00/rocketpool.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/rocketpool.yaml)

The latest supported version can always be found [Here](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/rocketpool.yaml#L7).

## Install Notes
Execute the `./scripts/quick-install.sh` script to build and configure a rocketpool node.
```
$ ./scripts/quick-install.sh -h
usage: bash ./scripts/quick-install.sh -a -y
-a    | --apply      This flag is required to deploy rocketpool.  Default action is 'plan'.
-d    | --dir        This sets the local workstation virtualenv install directory.
                     Default is '/home/jwitkowski/.virtualenvs/cloudstruct-rocketpool'
-h    | --help       Brings up this menu
-p    | --pool       Specify pool name.  Defaults to mainnet-00
-r    | --reinstall  By default this script will not re-install local workstation packages.  Set this to override that.
-y    | --yes        This answers 'yes' to all prompts automatically.
                     Without this flag manual acceptance/response is required during deployment.
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
- ansible will harden the instance, update packages, and install rocketpool (reboot if required)
- add cloudwatch alarms (slack alerts exist, email alerts coming soon) to the ASG+EC2 instance
- Create required security groups and lock down SSH+Grafana to ip-whitelist including option to dyamically add IP of executing workstation
- Installs rocketpool and node-exporter grafana dashboards

# Credit
- @tedsteen https://github.com/tedsteen/rocketpool for ansible galaxy and role inspiration
- @cloudstruct team for initial terraform code and layout
