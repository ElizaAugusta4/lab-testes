variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnetwork_id" {
  type = string
}

variable "deletion_protection" {
  type    = bool
  default = false
}
