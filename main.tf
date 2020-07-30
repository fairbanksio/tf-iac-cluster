variable "do_token" {}
variable "do_cluster_name" {}
variable "mariadb_user" {}
variable "mariadb_pw" {}

###
# Terraform Cloud
###

terraform {
  backend "remote" {
    organization = "Fairbanks-io"

    workspaces {
      name = "k8s-prod-us-sfo"
    }
  }
}

###
# DigitalOcean
###

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_kubernetes_cluster" "k8s" {
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

output "cluster-id" {
  value = digitalocean_kubernetes_cluster.k8s.id
}

###
# Helm
###

provider "helm" {
  kubernetes {
    config_path = digitalocean_kubernetes_cluster.k8s.kube_config.0.raw_config
  }
}

resource "helm_release" "maria-db" {
  name  = "maria-db"
  chart = "stable/mariadb"

  set {
    name  = "mariadbUser"
    value = var.mariadb_user
  }

  set {
    name  = "mariadbPassword"
    value = var.mariadb_pw
  }

  set_string {
    name  = "image.tags"
    value = "registry\\.io/terraform-provider-helm\\,example\\.io/terraform-provider-helm"
  }
}

resource "helm_release" "nginx-ingress" {
  name  = "nginx-ingress-lb"
  chart = "stable/nginx-ingress"

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "jetstack/cert-manager"
  version    = "v0.15.2"
  namespace  = "cert-manager"
}