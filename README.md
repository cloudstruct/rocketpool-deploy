# CloudStruct Rocketpool Deployment Automation
- [CloudStruct Rocketpool Deployment Automation](#cloudstruct-rocketpool-deployment-automation)
  * [AWS / Terraform and Ansible](#aws---terraform-and-ansible)
    + [Why?](#why-)
    + [Known limitations](#known-limitations)
    + [Pre-requisites](#pre-requisites)
    + [Pre-Install Notes](#pre-install-notes)
    + [Install Notes](#install-notes)
      - [Obtain Private SSH Key](#obtain-private-ssh-key)
    + [What does it do?](#what-does-it-do-)
  * [Local Ansible Run](#local-ansible-run)
    + [Why?](#why--1)
    + [Pre-requisites](#pre-requisites-1)
    + [Pre-Install Notes](#pre-install-notes-1)
    + [Install Notes](#install-notes-1)
  * [Post Install Instructions](#post-install-instructions)
  * [Hybrid Mode](#hybrid-mode)
  * [Credit](#credit)

## AWS / Terraform and Ansible
Automation to deploy/manage a Rocketpool Ethereum staking pool node

### Why?
You may be asking why does this repo exist?  Rocketpool already has a fantastic install guide, docker containers, docker-compose setup, etc.
The reasons someone might want to use this repo are:
* Production level deployment (Things like uptime, self-healing, monitoring, notifications for monitoring, and repeatability)
* You do not want to put the effort in to doing it manually.
* You do not want to concern yourself with constantly maintaining and updating your node
* You would like to leverage the experience and knowledge of a company filled with experts doing DevOps As A Service (CloudStruct)

### Known limitations
- Currently only built for AWS or local servers.
- Currently only supports `Debian >= 11` or `Ubuntu >= 16`

### Pre-requisites
- An AWS Account and AWS Access & Secret key credentials setup and ready to use
- An ubuntu CLI which has python3, python3-pip, and python3-venv installed.

### Pre-Install Notes
Take a look at and edit the following files as desired. The comments should provide context.
- [vars/defaults.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/defaults.yaml)
- [vars/pools/mainnet-00/aws.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/aws.yaml)
- [vars/pools/mainnet-00/node.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/node.yaml)
- [vars/pools/mainnet-00/rocketpool.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/rocketpool.yaml)

The latest supported version can always be found [Here](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/rocketpool.yaml#L7).

### Install Notes
Execute the `./scripts/quick-install.sh` script to build and configure a rocketpool node.
```
$ ./scripts/quick-install.sh -h
usage: bash ./scripts/quick-install.sh -a -y
-a    | --apply      This flag is required to deploy rocketpool.  Default action is 'plan'.
-d    | --dir        This sets the local workstation virtualenv install directory.
                     Default is '~/.virtualenvs/cloudstruct-rocketpool'
-h    | --help       Brings up this menu
-p    | --pool       Specify pool name.  Defaults to mainnet-00
-r    | --reinstall  By default this script will not re-install local workstation packages.  Set this to override that.
-y    | --yes        This answers 'yes' to all prompts automatically.
                     Without this flag manual acceptance/response is required during deployment.
```

#### Obtain Private SSH Key
If you set the config to generate an SSH key for you via AWS then you can use the following command to retrieve this key from the encrypted s3 bucket.
`terraform output -json | jq '.ssh_private_key.value' -r`

### What does it do?
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

## Local Ansible Run
This installation method only requires command line access to an Ubuntu/Debian server and the internet.  It does not use AWS.

### Why?
Why would someone want to use this to automate their local server?
The reasons someone might want to use the local ansible install method:
* Automated OS security hardening following industry best practices.
* Much faster than a manual installation
* Easily roll forward and backwards between versions
* You do not want to concern yourself with tracking the CHANGELOG of rocketpool repos and responding accordingly. 
* You would like to leverage the experience and knowledge of a company filled with experts doing DevOps As A Service (CloudStruct)

### Pre-requisites
- Access to an Ubuntu or Debian CLI and sudo privileges.

### Pre-Install Notes
Take a look at and edit the following files as desired. The comments should provide context.
- [vars/defaults.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/defaults.yaml)
- [vars/pools/mainnet-00/node.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/node.yaml)
- [vars/pools/mainnet-00/rocketpool.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/rocketpool.yaml)

The latest supported version can always be found [Here](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/rocketpool.yaml#L7).

*It is strongly advised to keep make copy of the `mainnet-00` directory into `mainnet-01` and edit your settings there.  This will make future upgrades much easier.*

### Install Notes
Execute the `./scripts/quick-install.sh` script to build and configure a rocketpool node.
```
$ ./scripts/local-ansible-install.sh -h
usage: bash ./scripts/local-ansible-install.sh -s
-h    | --help         Brings up this menu
-e    | --exclude      Comma separated value of actions to exclude.
                       Current options: ['firewall','reboot','rocketpool','security','ssh']
-p    | --pool         Specify pool name.  Defaults to mainnet-00
-r    | --reinstall    By default this script will not re-install local workstation packages.  Set this to override that.
-s    | --system-setup This flag requires sudo privileges.  It installs python3-venv and all dependencies on the system.

cp -R vars/pools/mainnet-00 vars/pools/mainnet-01
./scripts/local-ansible-install.sh -s -p mainnet-01
```

## Hybrid Mode
[Hybrid mode](https://docs.rocketpool.net/guides/node/hybrid.html) is supported.  To enable simply fill out the appropriate values in [vars/pools/mainnet-00/rocketpool.yaml](https://github.com/cloudstruct/rocketpool-deploy/blob/main/vars/pools/mainnet-00/rocketpool.yaml) for ETH1 `eth.eth1.provider` and `eth.eth1.wsProvider` and/or for ETH2 `eth.eth2.provider`. 

## Post Install Instructions
**You should always read all of the documentation.  This is not advice on avoiding that.**
After the installation you should return to the official Rocketpool documentation.  This will leave you off with needing to setup your wallet, stake your RPL, and then deposit.
At the time of this writing it should leave you off right about [Here](https://docs.rocketpool.net/guides/node/starting-rp.html).

## Credit
- @tedsteen https://github.com/tedsteen/rocketpool for initial inspiration
- @cloudstruct team for initial terraform code and layout
