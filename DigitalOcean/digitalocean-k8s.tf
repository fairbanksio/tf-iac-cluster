variable "do_token" {}
variable "do_cluster_name" {}
variable "dd_api_key" {}

# Get a Digital Ocean token from your Digital Ocean account
# See: https://www.digitalocean.com/docs/api/create-personal-access-token/
# Set TF_VAR_do_token to use your Digital Ocean token automatically
provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_kubernetes_cluster" "my_digital_ocean_cluster" {
  name    = var.do_cluster_name
  region  = "sfo2"
  auto_upgrade = true
  version = "1.18.6-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 2
  }
}

module "datadog" {
  source = "cookielab/datadog/kubernetes"
  version = "0.9.1"

  datadog_agent_api_key = var.dd_api_key
  datadog_agent_site = "datadoghq.com"
}

output "cluster-id" {
  value = digitalocean_kubernetes_cluster.my_digital_ocean_cluster.id
}
