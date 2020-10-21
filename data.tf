##
# Data
##

data "kubernetes_service" "nginx-ingress-controller" {
  metadata {
    name = "nginx-ingress-controller"
  }
  depends_on = [helm_release.ingress]
} 