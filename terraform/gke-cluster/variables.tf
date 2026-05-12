variable "gcp_project_id" {
  description = "GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for the GKE cluster."
  type        = string
}

variable "hcp_terraform_organization_id" {
  description = "HCP Terraform organization ID (not name) — used to scope the Workload Identity pool IAM binding."
  type        = string
}
