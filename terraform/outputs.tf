output "cluster_id" {
  description = "The ID of the LKE cluster"
  value       = linode_lke_cluster.main.id
}

output "cluster_status" {
  description = "The status of the LKE cluster"
  value       = linode_lke_cluster.main.status
}

output "api_endpoints" {
  description = "The API endpoints for the LKE cluster"
  value       = linode_lke_cluster.main.api_endpoints
}

output "kubeconfig" {
  description = "Base64 encoded kubeconfig for the cluster"
  value       = linode_lke_cluster.main.kubeconfig
  sensitive   = true
}

output "nodebalancer_id" {
  description = "The ID of the NodeBalancer for ingress"
  value       = linode_nodebalancer.ingress.id
}

output "nodebalancer_hostname" {
  description = "The hostname of the NodeBalancer for DNS configuration"
  value       = linode_nodebalancer.ingress.hostname
}

output "nodebalancer_ipv4" {
  description = "The IPv4 address of the NodeBalancer"
  value       = linode_nodebalancer.ingress.ipv4
}

