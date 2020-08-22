## Digital Ocean
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

## kube-state-metrics

resource "helm_release" "kube-state-metrics" {
  name       = "kube-state-metrics"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "kube-state-metrics"
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
  set {
    name  = "datadog.processAgent.enabled"
    value = "true"
  }
  set {
    name  = "datadog.processAgent.processCollection"
    value = "true"
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
  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }
  set {
    name  = "controller.config.proxy-body-size"
    value = "250m"
  }
  set {
    name  = "controller.config.client-max-body-size"
    value = "250m"
  }
  set {
    name  = "controller.config.proxy-connect-timeout"
    value = "60s"
  }
  set {
    name  = "controller.config.proxy-read-timeout"
    value = "60s"
  }
  set {
    name  = "controller.config.enable-real-ip"
    value = true
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