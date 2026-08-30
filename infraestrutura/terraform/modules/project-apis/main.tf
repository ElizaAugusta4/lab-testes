# ATENCAO: a Cloud Resource Manager API NAO pode ser habilitada aqui.
# O provider do Google precisa dela ja ligada pra conseguir gerenciar
# qualquer outra API - e um passo manual, uma vez so, documentado no
# README do ambiente (nao da pra automatizar sem cair num paradoxo de
# "preciso da API pra habilitar a API").
#
#   gcloud services enable cloudresourcemanager.googleapis.com --project=<id>

resource "google_project_service" "this" {
  for_each = toset(var.services)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}