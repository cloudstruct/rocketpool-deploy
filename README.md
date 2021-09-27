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

# Credit
- @tedsteen https://github.com/tedsteen/rocketpool for ansible galaxy and role inspiration
- @cloudstruct team for initial terraform code and layout
