variable environment {
  default = "dev"
}

variable location {
  default = "westeurope"
}

variable node_count {
  default = 2
}

variable dns_prefix {
  default = "dns-adminportal"
}

variable cluster_name {
  default = "adminportal-k8s"
}

variable resource_group {
  default = "adminportal-rg"
}

variable ssh_public_key {}
variable client_id {}
variable client_secret {}