# Workload Identity Federation: permite o GitHub Actions autenticar no GCP
# sem nenhuma chave JSON armazenada como secret - o GitHub prova quem ele
# e via um token OIDC de curta duracao, gerado na hora, pra cada execucao.
#
# Isso e o motivo de nao termos batido na mesma trava de
# "iam.disableServiceAccountKeyCreation" que travou o stackdriver-exporter
# no lab do Postgres - aqui nunca existe uma chave pra criar.

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Restringe pra SO aceitar tokens vindos do seu repositorio especifico -
  # sem isso, qualquer repositorio do GitHub poderia se passar por voce.
  attribute_condition = "assertion.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "ci" {
  account_id   = var.service_account_id
  display_name = "CI/CD - ${var.github_repo}"
}

resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.ci.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

resource "google_project_iam_member" "ci_roles" {
  for_each = toset(var.roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.ci.email}"
}
