## Digital Ocean

data "digitalocean_kubernetes_versions" "latest" {
  version_prefix = "1.24."
}

resource "digitalocean_kubernetes_cluster" "k8s" {
  name          = var.do_cluster_name
  region        = "sfo2"
  auto_upgrade  = true
  surge_upgrade = true
  version       = data.digitalocean_kubernetes_versions.latest.latest_version

  maintenance_policy {
    start_time = "13:00"
    day        = "sunday"
  }

  node_pool {
    name       = "worker-pool"
    size       = "s-1vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 3
  }
}


## FluxCD
locals {
  known_hosts = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
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
  depends_on = [
    digitalocean_kubernetes_cluster.k8s
  ]
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

  depends_on = [
    digitalocean_kubernetes_cluster.k8s
  ]
}

resource "helm_release" "fluxcd" {
  repository = "https://charts.fluxcd.io"
  chart      = "flux"
  name       = "fluxcd"
  namespace  = "flux-system"
  values = [
    <<EOT
git:
  url: "git@github.com:Fairbanks-io/flux-gitops-apps.git"
  secretName: "flux-system"
  path: "cluster"
  branch: "main"
registry:
  disableScanning: true
EOT
  ]
  depends_on = [
    digitalocean_kubernetes_cluster.k8s
  ]
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

  depends_on = [
    digitalocean_kubernetes_cluster.k8s
  ]
}

resource "cloudflare_record" "f5" {
  provider = cloudflare.cloudflare-fairbanks
  zone_id  = var.cloudflare_zone_id_fairbanks_dev
  name     = "f5"
  value    = "1.2.3.4"
  type     = "A"
  proxied  = true
}

resource "cloudflare_page_rule" "f5-redirect" {
  provider = cloudflare.cloudflare-fairbanks
  zone_id  = var.cloudflare_zone_id_fairbanks_dev
  target   = "f5.fairbanks.dev"
  priority = 1

  actions {
    forwarding_url {
      url         = "https://f5.news"
      status_code = 301
    }
  }
}

