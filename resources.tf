## Digital Ocean
resource "digitalocean_kubernetes_cluster" "k8s" {
  name         = var.do_cluster_name
  region       = "sfo2"
  auto_upgrade = false
  version      = "1.18.8-do.0"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 3
  }
}

#resource "digitalocean_spaces_bucket" "static-assets" {
#  name   = var.do_space_name
#  region = "sfo2"
#}

## kube-state-metrics

resource "helm_release" "kube-state-metrics" {
  name       = "kube-state-metrics"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "kube-state-metrics"
}

## Metrics Server

resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
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

## Grafana 

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

resource "helm_release" "grafana" {
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "grafana"
  name       = "grafana"
  namespace  = "grafana"
  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.hosts[0].name"
    value = cloudflare_record.grafana.hostname
  }
}

resource "cloudflare_record" "grafana" {
  zone_id = var.cloudflare_zone_id_fairbanks
  name    = "grafana"
  proxied = true
  value   = data.kubernetes_service.nginx-ingress-controller.load_balancer_ingress.0.ip
  type    = "A"
  ttl     = 1
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
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-enable-proxy-protocol"
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


## Prometheus

resource "kubernetes_namespace" "kube-metrics" {
  metadata {
    name = "kube-metrics"
  }
}

resource "helm_release" "prometheus" {
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart      = "prometheus-operator"
  name       = "prom-stats-monitoring"
  namespace  = "kube-metrics"
  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }
  set {
    name  = "grafana.ingress.hosts[0]"
    value = cloudflare_record.metrics.hostname
  }
  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_password
  }
}

resource "cloudflare_record" "metrics" {
  zone_id = var.cloudflare_zone_id
  name    = "metrics"
  proxied = true
  value   = data.kubernetes_service.nginx-ingress-controller.load_balancer_ingress.0.ip
  type    = "A"
  ttl     = 1
}