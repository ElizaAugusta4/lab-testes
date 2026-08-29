variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "repository_id" {
  type    = string
  default = "lab-images"
}

variable "ci_service_account_email" {
  type    = string
  default = null
}
