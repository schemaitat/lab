variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the LKE cluster"
  type        = string
  default     = "my-lke-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.29"
}

variable "region" {
  description = "Linode region for the cluster"
  type        = string
  default     = "us-central"
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = list(string)
  default     = ["terraform", "lke"]
}

variable "node_pools" {
  description = "Node pools configuration"
  type = list(object({
    type  = string
    count = number
  }))
  default = [
    {
      type  = "g6-nanode-1"
      count = 3
    }
  ]
}