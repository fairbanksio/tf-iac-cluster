data "digitalocean_kubernetes_cluster" "k8s" {
  name = "fairbanks-io"
}

data "kubernetes_service" "nginx-ingress-controller" {
  metadata {
    name = "ingress-ingress-nginx-controller"
  }
  depends_on = [helm_release.ingress]
}  