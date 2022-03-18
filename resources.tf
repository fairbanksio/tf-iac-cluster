## Digital Ocean

data "digitalocean_kubernetes_versions" "latest" {
  version_prefix = "1.21."
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
    size       = "s-2vcpu-4gb"
    auto_scale = true
    min_nodes  = 3
    max_nodes  = 5
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

resource "helm_release" "ingress" {
  repository = "https://charts.helm.sh/stable"
  chart      = "nginx-ingress"
  name       = "ingress"
  set {
    name  = "controller.service.name"
    value = "nginx-ingress-controller"
  }
  set {
    name  = "controller.autoscaling.enabled"
    value = true
  }
  set {
    name  = "controller.autoscaling.minReplicas"
    value = "2"
  }
  set {
    name  = "controller.autoscaling.maxReplicas"
    value = 3
  }
  set {
    name  = "controller.limits.cpu"
    value = "200m"
  }
  set {
    name  = "controller.autoscaling.targetCPUUtilizationPercentage"
    value = "50"
  }
  set {
    name  = "controller.autoscaling.minReplicas"
    value = "2"
  }
  set {
    name  = "controller.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "200Mi"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-enable-proxy-protocol"
    value = "true"
  }
  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
  set {
    name  = "controller.config.use-proxy-protocol"
    value = "true"
    type  = "string"
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
    value = "60"
    type  = "string"
  }
  set {
    name  = "controller.config.proxy-read-timeout"
    value = "60"
    type  = "string"
  }
  set {
    name  = "defaultBackend.enabled"
    value = "false"
  }
  set {
    name  = "controller.defaultBackendService"
    value = "default/pretty-default-backend"
  }

  set {
    name  = "topologySpreadConstraints[0].maxSkew"
    value = "1"
  }
  set {
    name  = "controller.topologySpreadConstraints[0].topologyKey"
    value = "kubernetes.io/hostname"
  }
  set {
    name  = "controller.topologySpreadConstraints[0].whenUnsatisfiable"
    value = "ScheduleAnyway"
  }
  set {
    name  = "controller.topologySpreadConstraints[0].labelSelector.matchLabels.app\\.kubernetes\\.io/app"
    value = "nginx-ingress"
  }
}

resource "helm_release" "pretty-default-backend" {
  name       = "pretty-default-backend"
  repository = "https://h.cfcr.io/bsord/charts"
  chart      = "pretty-default-backend"
  namespace  = "default"
  version    = "0.4.0"
  set {
    name  = "autoscaling.enabled"
    value = true
  }
  set {
    name  = "autoscaling.minReplicas"
    value = 2
  }
  set {
    name  = "bgColor"
    value = "#334455"
  }
  set {
    name  = "brandingText"
    value = "bsord.dev/fairbanks.dev"
  }
}