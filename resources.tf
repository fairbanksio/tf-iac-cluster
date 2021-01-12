## Digital Ocean
resource "digitalocean_kubernetes_cluster" "k8s" {
  name         = var.do_cluster_name
  region       = "sfo2"
  auto_upgrade = false
  version      = "1.18.10-do.3"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 3
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
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-enable-proxy-protocol"
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
  repository = "https://h.cfcr.io/fairbanks.io/default"
  chart      = "pretty-default-backend"
  namespace  = "default"
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