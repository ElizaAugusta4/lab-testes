output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_location" {
  value = module.gke.cluster_location
}

output "get_credentials_command" {
  value = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${module.gke.cluster_location} --project ${var.project_id}"
}

output "static_ip" {
  value = google_compute_global_address.lab.address
}

output "dns_record" {
  value = module.dns.dns_record
}

output "artifact_registry_url" {
  value = module.artifact_registry.repository_url
}

output "github_actions_workload_identity_provider" {
  description = "Cole isso no workflow do GitHub Actions"
  value       = module.github_oidc.workload_identity_provider
}

output "github_actions_service_account" {
  value = module.github_oidc.service_account_email
}
