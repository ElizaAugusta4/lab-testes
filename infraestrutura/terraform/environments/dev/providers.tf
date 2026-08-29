terraform {
  required_version = ">= 1.7.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.24"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }

  # Em producao de verdade, isso apontaria pra um backend remoto (GCS,
  # por exemplo) - deixado local aqui pra simplicidade do lab.
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
