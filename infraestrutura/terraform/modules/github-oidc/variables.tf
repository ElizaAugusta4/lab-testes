variable "project_id" {
  type = string
}

variable "github_repo" {
  type        = string
  description = "Formato: usuario/repositorio (ex: ElizaAugusta4/lab-testes)"
}

variable "pool_id" {
  type    = string
  default = "github-pool"
}

variable "provider_id" {
  type    = string
  default = "github-provider"
}

variable "service_account_id" {
  type    = string
  default = "github-ci"
}

variable "roles" {
  type        = list(string)
  description = "Roles no projeto pra service account da CI"
  default     = []
}
