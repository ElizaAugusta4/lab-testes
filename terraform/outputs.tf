output "cluster_name" {
  value = google_container_cluster.lab.name
}

output "cluster_location" {
  value = google_container_cluster.lab.location
}

output "get_credentials_command" {
  description = "Rode isso pra configurar o kubectl pra falar com o cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.lab.name} --region ${google_container_cluster.lab.location} --project ${var.project_id}"
}