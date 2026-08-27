variable "project_id" {
  type        = string
  description = "ID do seu projeto no GCP"
}

variable "region" {
  type        = string
  description = "Regiao do GCP (Autopilot clusters sao sempre regionais)"
  default     = "southamerica-east1"
}

variable "cluster_name" {
  type        = string
  description = "Nome do cluster GKE"
  default     = "lab-observability"
}