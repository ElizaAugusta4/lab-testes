resource "google_container_cluster" "this" {
  name     = var.cluster_name
  location = var.region

  enable_autopilot = true

  network    = var.network_id
  subnetwork = var.subnetwork_id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  # Facilita o "terraform destroy" no lab - em producao voce NAO quer isso.
  deletion_protection = var.deletion_protection
}
