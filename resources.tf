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
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  name       = "ingress"
  version    = "4.0.18"
  values = [
    <<EOT
rbac:
  create: true
controller:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 3
    targetCPUUtilizationPercentage: 50
  limits:
    cpu: 200m
  requests:
    cpu: 50m
    memory: 200Mi
  service:
    name: nginx-ingress-controller
    annotations:
      service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: true
  config:
    annotation-value-word-blocklist: "load_module,lua_package,_by_lua,root,proxy_pass,serviceaccount"
    use-proxy-protocol: "true"
    proxy-body-size: 250m
    client-max-body-size: 250m
    proxy-connect-timeout: "60"
    proxy-read-timeout: "60"
  affinity:
  # An example of required pod anti-affinity
  topologySpreadConstraints:
  - labelSelector:
      matchLabels:
        app.kubernetes.io/instance: kube-system-nginx-ingress
    maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
EOT
  ]

}

resource "helm_release" "pretty-default-backend" {
  name       = "pretty-default-backend"
  repository = "https://h.cfcr.io/bsord/charts"
  chart      = "pretty-default-backend"
  namespace  = "default"
  version    = "0.4.0"
  values = [
    <<EOT
autoscaling:
  enabled: false
  minReplicas: 2
bgColor: "#334455"
brandingText: "bsord.dev/fairbanks.dev"
EOT
  ]
}
