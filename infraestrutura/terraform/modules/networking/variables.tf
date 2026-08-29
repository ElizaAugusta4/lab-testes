variable "name_prefix" {
  type        = string
  description = "Prefixo pro nome dos recursos (ex: nome do cluster)"
}

variable "region" {
  type = string
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/20"
}

variable "pods_cidr" {
  type    = string
  default = "10.20.0.0/14"
}

variable "services_cidr" {
  type    = string
  default = "10.30.0.0/20"
}
