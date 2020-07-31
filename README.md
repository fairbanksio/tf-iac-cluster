# Terraform

![GitHub top language](https://img.shields.io/github/languages/top/jonfairbanks/terraform.svg)
![GitHub last commit](https://img.shields.io/github/last-commit/jonfairbanks/terraform.svg)
![Terraform](https://github.com/jonfairbanks/terraform/workflows/Terraform/badge.svg?branch=master)
![License](https://img.shields.io/github/license/jonfairbanks/terraform.svg?style=flat)

### Terraform Plans

Spin up a developer ready Kubernetes cluster in DigitalOcean using Terraform protected by CloudFlare.

##### Prerequisites
- A pre-configured Terraform Cloud account and API key
- A local Terraform host or automated pipeline

##### Setup
- Download the latest binary from Terraform.io: https://www.terraform.io/downloads.html
- Unzip the binary into /usr/bin/local and set as executable

##### Usage
- `cd` to the plan of your choice
- Run `terraform plan` to initiate a dry-run
- Execute `terraform apply` to apply the plan

##### GitHub Integration
Instead of running the Terraform script manually, changes can be automated via GitHub Actions. 

For more information, follow the setup here: https://github.com/jonfairbanks/terraform/blob/master/.github/workflows/terraform.yml
