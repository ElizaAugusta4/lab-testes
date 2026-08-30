# ==============================================================================
# APIs necessarias no projeto
# ==============================================================================
resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container" {
  project            = var.project_id
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iamcredentials" {
  project            = var.project_id
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

# ==============================================================================
# Rede
# ==============================================================================
module "networking" {
  source = "../../modules/networking"

  name_prefix = var.cluster_name
  region      = var.region

  depends_on = [google_project_service.compute]
}

# ==============================================================================
# Cluster GKE Autopilot
# ==============================================================================
module "gke" {
  source = "../../modules/gke-autopilot"

  cluster_name  = var.cluster_name
  region        = var.region
  network_id    = module.networking.network_id
  subnetwork_id = module.networking.subnetwork_id

  depends_on = [google_project_service.container]
}

# ==============================================================================
# Identidade da pipeline de CI/CD (sem chave/senha)
# ==============================================================================
module "github_oidc" {
  source = "../../modules/github-oidc"

  project_id  = var.project_id
  github_repo = var.github_repo

  roles = [
    "roles/compute.networkAdmin",           # VPC, subnet, IP fixo
    "roles/container.admin",                # cluster GKE completo
    "roles/artifactregistry.admin",         # repositorio + IAM dele
    "roles/serviceusage.serviceUsageAdmin", # habilitar APIs
  ]

  depends_on = [google_project_service.iamcredentials]
}

# A CI precisa poder ler/escrever no bucket de state remoto - permissao
# so nesse bucket especifico, nao no Storage do projeto inteiro.
resource "google_storage_bucket_iam_member" "ci_state_access" {
  bucket = "lab-observability-tfstate"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.github_oidc.service_account_email}"
}

# ==============================================================================
# Artifact Registry - imagens Docker
# ==============================================================================
module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id               = var.project_id
  region                   = var.region
  ci_service_account_email = module.github_oidc.service_account_email

  depends_on = [google_project_service.artifactregistry]
}

# ==============================================================================
# DNS - IP fixo + registro na Cloudflare
# ==============================================================================
resource "google_compute_global_address" "lab" {
  name       = "${var.cluster_name}-ip"
  depends_on = [google_project_service.compute]
}

module "dns" {
  source = "../../modules/dns-cloudflare"

  zone_id    = var.cloudflare_zone_id
  subdomain  = var.subdomain
  ip_address = google_compute_global_address.lab.address
  comment    = "Lab GKE - aponta pro Ingress do cluster ${var.cluster_name}"
}