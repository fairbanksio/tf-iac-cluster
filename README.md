# DigitalOcean k8s with Terraform

![GitHub top language](https://img.shields.io/github/languages/top/jonfairbanks/terraform.svg)
![GitHub last commit](https://img.shields.io/github/last-commit/jonfairbanks/terraform.svg)
![Terraform](https://github.com/jonfairbanks/terraform/workflows/Terraform/badge.svg?branch=master)
![License](https://img.shields.io/github/license/jonfairbanks/terraform.svg?style=flat)

### Terraform Plans

Spin up a developer ready Kubernetes cluster in DigitalOcean using Terraform. Protected by CloudFlare; monitored with Datadog.

##### Prerequisites
- [A Terraform Cloud API key](https://www.terraform.io/docs/cloud/users-teams-organizations/api-tokens.html)
- [DigitalOcean Personal Access Token](https://www.digitalocean.com/docs/apis-clis/api/create-personal-access-token/)
- [DigitalOcean Spaces Access ID and Secret Key](https://www.digitalocean.com/community/tutorials/how-to-create-a-digitalocean-space-and-api-key#creating-an-access-key)
- [CloudFlare GLOBAL API key (not API token)](https://support.cloudflare.com/hc/en-us/articles/200167836-Managing-API-Tokens-and-Keys)
- [Datadog API key](https://docs.datadoghq.com/account_management/api-app-keys/)
- Optional: [Terraform installed locally](https://learn.hashicorp.com/terraform/getting-started/install.html) *Make sure to install > v0.12.29*


##### Setup
1. Fork this repo

2. [Store your Terraform Cloud API key as a secret called  **TF_API_TOKEN**  in the Github repo](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets)

3. [Create a workspace](https://www.terraform.io/docs/cloud/workspaces/creating.html) in Terraform Cloud called **k8s-prod-us-sfo** and connect it to your forked repo
  
4. [Define the below variables in the Terraform Cloud workspace](https://www.terraform.io/docs/cloud/workspaces/variables.html#managing-variables-in-the-ui "Define the below variables in the Terraform Cloud workspace")

| Variable | Description |
| ------------ | ------------ |
| `do_token` | Your DigitalOcean access token |
| `do_cluster_name` | Name of the Kubernetes cluster |
| `do_space_name` | DigitalOcean Space Name|
| `do_access_id` | DigitalOcean Space Access Key |
| `do_secret_key` | DigitalOcean Space Secret |
| `dd_api_key` | Datadog API Key |
| `cloudflare_email` | Cloudflare Account Email |
| `cloudflare_api_key` | GLOBAL API key for Cloudflare (not token) |
| `cloudflare_zone_id` | ZoneID used to create DNS record |
| `mongo_root` | MongoDB Root Password |
| `mongo_user` | MongoDB User Account |
| `mongo_pw` | MongoDB User Password |

5. Trigger intial plan and apply to create the state
In the workspace, on app.terraform.io, click 'queue plan'
Wait for the plan to complete and click 'confirm' to run the initial apply

6. Set workspace type to Local
In the workspace, on app.terraform.io, click 'settings' -> General
Change the Execution Mode to Local. This will change the runs to complete automatically via the github action on future commits.

##### Deployment
###### 
###### Automatic Deployment
  1. Commit a code change to develop Branch
  2. Watch 'github actions' of repo on github.com to validate the 'Planning' phase
  3. Merge to master branch and watch 'github actions' to validate the 'Apply' phase completed succesfully
  4. Validate on Digital Ocean that cluster has been created
  
###### Local/Manual Deployment
  1. Clone this repo and `cd` into it
  2. Run `terraform init` to prepare Terraform
  3. Run `terraform plan` to do a dry-run
  4. run `terraform apply` to apply the plan
  5. Validate on Digital Ocean that cluster has been created.
  
##### Accessing Cluster
  - Click on the 'actions' of the cluster in Digital Ocean to 'Download Kube Config'
  - Alternatively: run `get-config.sh` from this repo

## TODO
- [ ] Allow Terraform workspace to be defined via variable
- [ ] Rename do_Access_id to 'do_spaces_access_key'
- [ ] Rename do_secret_key to 'do_spaces_secret_key'
- [ ] Add 'troubleshooting section' to README
