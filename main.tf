variable "do_token" {}
variable "do_cluster_name" {}
variable "do_access_id" {}
variable "do_secret_key" {}
variable "do_space_name" {}
variable "dd_api_key" {}
variable "cloudflare_email" {}
variable "cloudflare_api_key" {}
variable "cloudflare_zone_id" {}
variable "mongo_root" {}
variable "mongo_user" {}
variable "mongo_pw" {}

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
  token             = var.do_token
  spaces_access_id  = var.do_access_id
  spaces_secret_key = var.do_secret_key
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

resource "digitalocean_spaces_bucket" "static-assets" {
  name   = var.do_space_name
  region = "sfo2"
}

output "cluster-id" {
  value = digitalocean_kubernetes_cluster.k8s.id
}

###
# Helm
###

provider "helm" {
  kubernetes {
    load_config_file       = false
    host                   = digitalocean_kubernetes_cluster.k8s.endpoint
    token                  = digitalocean_kubernetes_cluster.k8s.kube_config.0.token
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
  }
}

## MongoDB

resource "kubernetes_namespace" "mongodb" {
  metadata {
    name = "mongodb"
  }
}

resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb-sharded"
  namespace  = "mongodb"
  set {
    name  = "mongodbRootPassword"
    value = var.mongo_root
  }
  set {
    name  = "mongodbUsername"
    value = var.mongo_user
  }
  set {
    name  = "mongodbPassword"
    value = var.mongo_pw
  }
  set {
    name  = "mongodbDatabase"
    value = var.do_cluster_name
  }
}

## Keel

resource "helm_release" "keel" {
  name       = "keel"
  repository = "https://charts.keel.sh"
  chart      = "keel"
  namespace  = "kube-system"
  set {
    name  = "helmProvider.version"
    value = "v3"
  }
}

## Datadog 

resource "kubernetes_namespace" "datadog" {
  metadata {
    name = "datadog"
  }
}

resource "helm_release" "datadog" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "datadog"
  name       = "datadog"
  namespace  = "datadog"
  set {
    name  = "datadog.apiKey"
    value = var.dd_api_key
  }
}

## Nginx 

resource "helm_release" "ingress" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "nginx-ingress"
  name       = "ingress"
  set {
    name  = "controller.service.name"
    value = "nginx-ingress-controller"
  }
}

provider "kubernetes" {
  load_config_file       = false
  host                   = digitalocean_kubernetes_cluster.k8s.endpoint
  token                  = digitalocean_kubernetes_cluster.k8s.kube_config.0.token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
}

data "kubernetes_service" "nginx-ingress-controller" {
  metadata {
    name = "ingress-nginx-ingress-controller"
  }
  depends_on = [helm_release.ingress]
}

##
# Output
##

output "ingress-ip" {
  value = data.kubernetes_service.nginx-ingress-controller.load_balancer_ingress.0.ip
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

# Add a record to the domain
resource "cloudflare_record" "terraform" {
  zone_id = var.cloudflare_zone_id
  name    = "terraform"
  proxied = true
  value   = data.kubernetes_service.nginx-ingress-controller.load_balancer_ingress.0.ip
  type    = "A"
  ttl     = 1
}