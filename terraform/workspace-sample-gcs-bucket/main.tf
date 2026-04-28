resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "demo" {
  name          = "hcp-agents-demo-${random_id.bucket_suffix.hex}"
  location      = var.gcp_region
  force_destroy = true

  uniform_bucket_level_access = true

  labels = {
    managed-by  = "terraform"
    environment = "demo"
    purpose     = "hcp-terraform-agents"
  }
}
