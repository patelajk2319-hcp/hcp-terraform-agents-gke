variable "hcp_terraform_token" {
  description = "HCP Terraform team or organization API token."
  type        = string
  sensitive   = true
}

variable "hcp_terraform_organization" {
  description = "HCP Terraform organization name."
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID where the GCS bucket will be deployed."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for the GCS bucket."
  type        = string
}
