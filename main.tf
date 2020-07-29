variable "do_token" {}
variable "do_cluster_name" {}
variable "dd_api_key" {}
variable "rancher_url" {}
variable "rancher_api_key" {}
variable "rancher_secret" {}

# The configuration for the `remote` backend.
terraform {
  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "Fairbanks-io"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "k8s-prod-us-sfo"
    }
  }
}

# Get a Digital Ocean token from your Digital Ocean account
# See: https://www.digitalocean.com/docs/api/create-personal-access-token/
# Set TF_VAR_do_token to use your Digital Ocean token automatically

provider "digitalocean" {
  token = var.do_token
}

provider "rancher" {
  api_url = var.rancher_url
  access_key = var.rancher_api_key
  secret_key = var.rancher_secret
}

resource "digitalocean_kubernetes_cluster" "my_digital_ocean_cluster" {
  name         = var.do_cluster_name
  region       = "sfo2"
  auto_upgrade = true
  version      = "1.18.6-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 3
  }
}

module "datadog" {
  source  = "cookielab/datadog/kubernetes"
  version = "0.9.1"

  datadog_agent_api_key = var.dd_api_key
  datadog_agent_site    = "datadoghq.com"
}

output "cluster-id" {
  value = digitalocean_kubernetes_cluster.my_digital_ocean_cluster.id
}
