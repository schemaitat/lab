terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

resource "linode_lke_cluster" "main" {
  label       = var.cluster_name
  k8s_version = var.kubernetes_version
  region      = var.region
  tags        = var.tags

  dynamic "pool" {
    for_each = var.node_pools
    content {
      type  = pool.value.type
      count = pool.value.count
    }
  }
}

# NodeBalancer for ingress traffic
resource "linode_nodebalancer" "ingress" {
  label  = "${var.cluster_name}-ingress"
  region = var.region
  tags   = concat(var.tags, ["ingress"])
}

# NodeBalancer config for HTTP (redirects to HTTPS)
resource "linode_nodebalancer_config" "http" {
  nodebalancer_id = linode_nodebalancer.ingress.id
  port            = 80
  protocol        = "http"
  algorithm       = "roundrobin"
  stickiness      = "none"
  check           = "http_body"
  check_path      = "/healthz"
  check_attempts  = 3
  check_timeout   = 30
  check_interval  = 40
}

# NodeBalancer config for HTTPS
resource "linode_nodebalancer_config" "https" {
  nodebalancer_id = linode_nodebalancer.ingress.id
  port            = 443
  protocol        = "tcp"
  algorithm       = "roundrobin"
  stickiness      = "none"
  check           = "connection"
  check_attempts  = 3
  check_timeout   = 30
  check_interval  = 40
}

# Note: NodeBalancer nodes will be added after cluster creation
# Run 'task setup' first, then 'task apply' to add the nodes