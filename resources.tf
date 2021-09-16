## Digital Ocean

resource "digitalocean_kubernetes_cluster" "k8s" {
  name          = var.do_cluster_name
  region        = "sfo2"
  auto_upgrade  = true
  surge_upgrade = true
  version       = "1.21.3-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-4gb"
    auto_scale = true
    min_nodes  = 4
    max_nodes  = 5
  }
}


## FluxCD
locals {
  known_hosts = "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=="
}

resource "kubernetes_namespace" "flux" {
  metadata {
    name = "flux-system"
  }
  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}

resource "kubernetes_secret" "flux-system" {
  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }
  data = {
    identity    = var.flux_deploy_key
    known_hosts = local.known_hosts
  }
}

resource "helm_release" "fluxcd" {
  repository = "https://charts.fluxcd.io"
  chart      = "flux"
  name       = "fluxcd"
  namespace  = "flux-system"
  set {
    name  = "git.url"
    value = "git@github.com:Fairbanks-io/flux-gitops-apps.git"
  }
  set {
    name  = "git.secretName"
    value = "flux-system"
  }
  set {
    name  = "git.path"
    value = "cluster"
  }
  set {
    name  = "git.branch"
    value = "main"
  }
  set {
    name  = "registry.disableScanning"
    value = true
  }
}

resource "kubernetes_secret" "sealed-secret-custom-key" {
  metadata {
    name      = "customkey"
    namespace = "kube-system"
    labels = {
      "sealedsecrets.bitnami.com/sealed-secrets-key" = "active"
    }
  }
  data = {
    "tls.crt" = var.sealed_sec_pub
    "tls.key" = var.sealed_sec
  }
  type = "kubernetes.io/tls"
}