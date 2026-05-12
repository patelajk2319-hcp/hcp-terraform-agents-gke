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

variable "workload_identity_audience" {
  description = "Workload Identity audience — output of the gke-cluster module. Set as TFC_WORKLOAD_IDENTITY_AUDIENCE in the workspace."
  type        = string
}

variable "workload_identity_provider_name" {
  description = "Full WIF provider resource name — output of the gke-cluster module. Set as TFC_GCP_WORKLOAD_PROVIDER_NAME in the workspace."
  type        = string
}

variable "agent_sa_email" {
  description = "Email of the SA HCP Terraform agent runs impersonate. Set as TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL in the workspace."
  type        = string
}
