variable "gcp_project_id" {
  description = "GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "GCP region (used by the Google provider)."
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name — used as a prefix for WIF resource IDs."
  type        = string
}

variable "hcp_terraform_organization_id" {
  description = "HCP Terraform organization ID (not name) — used to scope the Workload Identity pool IAM binding."
  type        = string
}
