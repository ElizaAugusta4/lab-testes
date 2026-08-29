output "workload_identity_provider" {
  description = "Cole isso no workflow do GitHub Actions (google-github-actions/auth)"
  value       = "projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.github.workload_identity_pool_provider_id}"
}

output "service_account_email" {
  value = google_service_account.ci.email
}
