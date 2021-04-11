## Digital Ocean
resource "digitalocean_kubernetes_cluster" "k8s" {
  name         = var.do_cluster_name
  region       = "sfo2"
  auto_upgrade = true
  version      = "1.20.2-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-4gb"
    auto_scale = true
    min_nodes  = 3
    max_nodes  = 3
  }
}

## Spaces
#resource "digitalocean_spaces_bucket" "static-assets" {
#  name   = var.do_space_name
#  region = "sfo2"
#}

## Metrics Server

resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = "https://charts.helm.sh/stable"
  chart      = "metrics-server"
  set {
    name  = "hostNetwork.enabled"
    value = "true"
  }
  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }
  set {
    name  = "replicas"
    value = "2"
  }
  set {
    name  = "podDisruptionBudget.enabled"
    value = true
  }
  set {
    name  = "podDisruptionBudget.minAvailable"
    value = "1"
  }
}

## Datadog 

resource "kubernetes_namespace" "datadog" {
  metadata {
    name = "datadog"
  }
}

resource "helm_release" "datadog" {
  repository = "https://charts.helm.sh/stable"
  chart      = "datadog"
  name       = "datadog"
  namespace  = "datadog"
  set_sensitive {
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
  set {
    name  = "datadog.nodeLabelsAsTags"
    value = "true"
  }
  set {
    name  = "datadog.podAnnotationsAsTags"
    value = "true"
  }
  set {
    name  = "datadog.podLabelsAsTags"
    value = "true"
  }
  set {
    name  = "datadog.apm.enabled"
    value = "true"
  }
  set {
    name  = "datadog.dogstatsd.nonLocalTraffic"
    value = "true"
  }
  set {
    name  = "datadog.dogstatsd.useHostPort"
    value = "true"
  }
  set {
    name  = "datadog.systemProbe.enabled"
    value = "true"
  }
}

## Nginx 

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
    name  = "tcp.25"
    value = "rcvr/rcvr-smtp:25"
    type  = "string"
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


## Argo CD
/*
resource "kubernetes_namespace" "argo-cd" {
  metadata {
    name = "argo-cd"
  }
}

resource "helm_release" "argo-cd" {
  name       = "argo-cd"
  namespace  = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  set {
    name  = "installCRDs"
    value = "false"
  }
}


## Monitoring

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "loki-stack" {
  name       = "loki-stack"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/loki/charts"
  chart      = "loki-stack"
  values = [<<-EOT
    grafana:
      plugins:
        - grafana-piechart-panel
      dashboardProviders:
        dashboardproviders.yaml:
          apiVersion: 1
          providers:
            - name: default
              orgId: 1
              folder:
              type: file
              disableDeletion: true
              editable: false
              options:
                path: /var/lib/grafana/dashboards/default
      dashboards:
        default:
          loki-dashboard:
            gnetId: 12611
            revision: 1
            datasource: Loki
          prometheus-stats:
            gnetId: 10000
            revision: 1
            datasource: Prometheus
  EOT
  ]
  set {
    name  = "grafana.enabled"
    value = "true"
  }
  set {
    name  = "prometheus.enabled"
    value = "true"
  }
  set {
    name  = "prometheus.alertmanager.persistentVolume.enabled"
    value = "false"
  }
  set {
    name  = "prometheus.server.persistentVolume.enabled"
    value = "false"
  }
  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }
  set {
    name  = "grafana.plugins[0]"
    value = "grafana-piechart-panel"
  }
  set {
    name  = "dashboardsProvider.enabled"
    value = "true"
  }
  set {
    name  = "grafana.ingress.hosts[0]"
    value = cloudflare_record.monitor.hostname
  }
  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_password
  }
}

resource "cloudflare_record" "monitor" {
  zone_id = var.cloudflare_zone_id
  name    = "monitor"
  proxied = true
  value   = data.kubernetes_service.nginx-ingress-controller.load_balancer_ingress.0.ip
  type    = "A"
  ttl     = 1
} */

## Node Problem Detector

resource "helm_release" "node-problem-detector" {
  repository = "https://charts.helm.sh/stable"
  chart      = "node-problem-detector"
  name       = "node-problem-detector"
  namespace  = "kube-system"
}

## FluxCD
# SSH
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
    identity = var.flux_deploy_key
    known_hosts    = local.known_hosts
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
    namespace = "flux-system"
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