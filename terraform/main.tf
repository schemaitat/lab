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

# Data source to get node details
data "linode_lke_cluster" "main" {
  id = linode_lke_cluster.main.id
  depends_on = [linode_lke_cluster.main]
}

# Get the instance details to retrieve IP addresses
data "linode_instances" "cluster_nodes" {
  filter {
    name = "tags"
    values = ["lke-cluster-${linode_lke_cluster.main.id}"]
  }
  depends_on = [linode_lke_cluster.main]
}

# NodeBalancer nodes for HTTP
resource "linode_nodebalancer_node" "http" {
  count           = length(data.linode_instances.cluster_nodes.instances)
  nodebalancer_id = linode_nodebalancer.ingress.id
  config_id       = linode_nodebalancer_config.http.id
  address         = "${data.linode_instances.cluster_nodes.instances[count.index].ip_address}:30080"
  label           = "node-${count.index + 1}-http"
  mode            = "accept"
  weight          = 100
}

# NodeBalancer nodes for HTTPS  
resource "linode_nodebalancer_node" "https" {
  count           = length(data.linode_instances.cluster_nodes.instances)
  nodebalancer_id = linode_nodebalancer.ingress.id
  config_id       = linode_nodebalancer_config.https.id
  address         = "${data.linode_instances.cluster_nodes.instances[count.index].ip_address}:30443"
  label           = "node-${count.index + 1}-https"
  mode            = "accept"
  weight          = 100
}