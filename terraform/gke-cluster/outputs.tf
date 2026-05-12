output "cluster_name" {
  description = "GKE cluster name (includes random suffix)."
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE cluster API endpoint."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate."
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "GKE cluster location."
  value       = google_container_cluster.primary.location
}

output "node_service_account_email" {
  description = "Email of the GKE node service account."
  value       = google_service_account.gke_nodes.email
}

output "vpc_name" {
  description = "VPC network name."
  value       = google_compute_network.vpc.name
}

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
