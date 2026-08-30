variable "project_id" {
  type        = string
  description = "ID do seu projeto"
}

variable "region" {
  type    = string
  default = "southamerica-east1"
}

variable "cluster_name" {
  type    = string
  default = "lab-observability"
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type = string
}

variable "subdomain" {
  type    = string
  default = "hello.lab.elizaaugusta.uk"
}

variable "github_repo" {
  type        = string
  description = "Formato: usuario/repositorio"
  default     = "ElizaAugusta4/lab-testes"
}
