# Terraform

![GitHub top language](https://img.shields.io/github/languages/top/jonfairbanks/terraform.svg)
![GitHub last commit](https://img.shields.io/github/last-commit/jonfairbanks/terraform.svg)
![Terraform](https://github.com/jonfairbanks/terraform/workflows/Terraform/badge.svg?branch=master)
![License](https://img.shields.io/github/license/jonfairbanks/terraform.svg?style=flat)

### Terraform Plans

Spin up a developer ready Kubernetes cluster in DigitalOcean using Terraform protected by CloudFlare with monitoring/logging available in DataDog.

##### Prerequisites
- A Terraform Cloud API key
  - https://www.terraform.io/docs/cloud/users-teams-organizations/api-tokens.html

- Digital Ocean Personal Access Token
  - https://www.digitalocean.com/docs/apis-clis/api/create-personal-access-token/

- Digital Ocean Spaces Access ID and Secret Key
  - https://www.digitalocean.com/community/tutorials/how-to-create-a-digitalocean-space-and-api-key#creating-an-access-key
  
- CloudFlare GLOBAL API key (not api token)
  - https://support.cloudflare.com/hc/en-us/articles/200167836-Managing-API-Tokens-and-Keys
  
- Datadog API key
  - https://docs.datadoghq.com/account_management/api-app-keys/
  
- Terraform installed locally (Optional)
  - https://learn.hashicorp.com/terraform/getting-started/install.html
  *Make sure to install > v0.12.29*


##### Setup
1. Fork this repo

2. Store your Terraform Cloud API key as a secret called  **TF_API_TOKEN**  in the github repo
  - https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets
3. Create workspace in terraform cloud called **k8s-prod-us-sfo** and connect it to your forked repo
  - https://www.terraform.io/docs/cloud/workspaces/creating.html
  
4. Define the below variables in the terraform workspace
https://www.terraform.io/docs/cloud/workspaces/variables.html#managing-variables-in-the-ui

  - do_token
    - Your digital ocean personal access token

  - do_cluster_name
    - The name of the kubernetes cluster to be created in digital ocean

  - do_access_id
    - The 'Key' from Digital Spaces Access Key 

  - do_secret_key
     - The 'Secret' from Digital Spaces Access Key

  - do_space_name
     - The name you wish to call the spaces object to be created on digital ocean

  - dd_api_key
     - API key for DataDog

  - cloudflare_email
     - Email address used on CloudFlare account where key is created

  - cloudflare_api_key
     - GLOBAL API key for cloud flare (not token)

  - cloudflare_zone_id
     - ZoneID of the DNS zone to be used to create dns record (can be found on bottom right of overview page for the DNS zone in the cloudflare portal)

  - mongo_root
     - Desired root password for MongoDB deployment

  - mongo_user
     - Desired password of the user account created for the MongoDB deployment

  - mongo_pw
     - Desired password of the user account created for the MongoDB deployment

##### Deployment
###### Automatic Deployment
  1. Commit a code change to develop Branch
  2. Watch 'github actions' of repo on github.com to validate the 'Planning' phase
  3. Merge to master branch and watch 'github actions' to validate the 'Apply' phase completed succesfully
  4. Validate on Digital Ocean that cluster has been created
  
###### Local/Manual Deployment
  1. clone this repo down to local PC where terraform installed
  2. CD into root of this repo
  3. Run `terraform init`
  4. Run 'terraform plan'
  5. run 'terraform apply'
  6. Validate on Digital Ocean that cluster has been created.
  
##### Accessing Cluster
  - Click on the 'actions' of the cluster in Digital Ocean to 'download kube config'
  - Alternatively: run get-config.sh from this repo.

## TODO
- Allow Terraform workspace to be defined via variable
- Rename do_Access_id to 'do_spaces_access_key'
- Rename do_secret_key to 'do_spaces_secret_key'
- Add 'troubleshooting section' to README
