variable "project_id" {
  type = string
}

variable "services" {
  type        = list(string)
  description = "Lista de APIs a habilitar (ex: compute.googleapis.com)"
}