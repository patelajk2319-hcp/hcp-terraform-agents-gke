output "workload_identity_audience" {
  description = "Audience value to set as TFC_WORKLOAD_IDENTITY_AUDIENCE in HCP Terraform workspaces."
  value       = "//iam.googleapis.com/${google_iam_workload_identity_pool.hcp_terraform.name}"
}

output "workload_identity_provider_name" {
  description = "Full resource name of the Workload Identity pool provider."
  value       = google_iam_workload_identity_pool_provider.hcp_terraform.name
}

output "hcp_terraform_agent_sa_email" {
  description = "Email of the SA that HCP Terraform agent runs impersonate via WIF."
  value       = google_service_account.hcp_terraform_agent.email
}
