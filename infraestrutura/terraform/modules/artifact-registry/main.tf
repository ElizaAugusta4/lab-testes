data "google_project" "current" {
  project_id = var.project_id
}

resource "google_artifact_registry_repository" "this" {
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
}

# Os nodes do GKE Autopilot usam a service account padrao de Compute do
# projeto pra puxar imagens - sem essa permissao, o kubelet recebe 403.
resource "google_artifact_registry_repository_iam_member" "gke_pull" {
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

# A pipeline de CI/CD tambem precisa poder ESCREVER (push) - concedido
# separadamente pro service account dela (veja modulo github-oidc).
resource "google_artifact_registry_repository_iam_member" "ci_push" {
  count      = var.ci_service_account_email != null ? 1 : 0
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.ci_service_account_email}"
}
