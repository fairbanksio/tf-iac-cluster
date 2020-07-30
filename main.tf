variable "do_token" {}
variable "do_cluster_name" {}
variable "mariadb_user" {}
variable "mariadb_pw" {}

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

resource "helm_release" "maria-db" {
    name      = "maria-db"
    chart     = "stable/mariadb"

    set {
        name  = "mariadbUser"
        value = var.mariadb_user
    }

    set {
        name = "mariadbPassword"
        value = var.mariadb_pw
    }

    set_string {
        name = "image.tags"
        value = "registry\\.io/terraform-provider-helm\\,example\\.io/terraform-provider-helm"
    }
}

output "cluster-id" {
  value = digitalocean_kubernetes_cluster.my_digital_ocean_cluster.id
}
