##
# Output
##

output "ingress-ip" {
  value = data.kubernetes_service.nginx-ingress-controller.load_balancer_ingress.0.ip
}

output "cluster-id" {
  value = digitalocean_kubernetes_cluster.k8s.id
}