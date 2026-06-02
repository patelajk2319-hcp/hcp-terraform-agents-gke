data "google_client_config" "default" {}

data "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.gcp_region
  project  = var.gcp_project_id
}
