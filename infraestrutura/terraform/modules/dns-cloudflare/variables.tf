variable "zone_id" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "ip_address" {
  type = string
}

variable "comment" {
  type    = string
  default = "Gerenciado via Terraform"
}
