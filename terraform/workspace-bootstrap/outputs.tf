output "workspace_url" {
  description = "URL to the workspace in HCP Terraform."
  value       = "https://app.terraform.io/app/${var.hcp_terraform_organization}/workspaces/${local.workspace_name}"
}
