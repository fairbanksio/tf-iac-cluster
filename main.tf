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
  version = "1.0.0"
  kubernetes {
    load_config_file       = false
    host                   = digitalocean_kubernetes_cluster.k8s.endpoint
    token                  = digitalocean_kubernetes_cluster.k8s.kube_config.0.token
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
  }
}

data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

resource "helm_release" "maria-db" {
  name       = "maria-db"
  repository = data.helm_repository.stable.url
  chart      = "stable/mariadb"

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
  name       = "nginx-ingress-lb"
  repository = data.helm_repository.stable.url
  chart      = "stable/nginx-ingress"

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = data.helm_repository.stable.url
  chart      = "jetstack/cert-manager"
  version    = "v0.16.0"
  namespace  = "cert-manager"
}