terraform {
  required_version = ">= 1.7.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.24"
    }
  }
}