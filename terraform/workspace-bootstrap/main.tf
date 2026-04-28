data "tfe_agent_pool" "non_prod" {
  name         = local.agent_pool
  organization = var.hcp_terraform_organization
}

resource "tfe_project" "demo" {
  name         = local.project_name
  organization = var.hcp_terraform_organization
}

resource "tfe_workspace" "demo" {
  name              = local.workspace_name
  organization      = var.hcp_terraform_organization
  project_id        = tfe_project.demo.id
  terraform_version = "~> 1.5"
  auto_apply        = false
  force_delete      = true
  tag_names         = ["demo", "gke-agents", "gcs"]
}

resource "tfe_workspace_settings" "demo" {
  workspace_id   = tfe_workspace.demo.id
  execution_mode = "agent"
  agent_pool_id  = data.tfe_agent_pool.non_prod.id
}

# ── Workspace variables ───────────────────────────────────────────────────────

resource "tfe_variable" "gcp_project_id" {
  key          = "gcp_project_id"
  value        = var.gcp_project_id
  category     = "terraform"
  workspace_id = tfe_workspace.demo.id
}

resource "tfe_variable" "gcp_region" {
  key          = "gcp_region"
  value        = var.gcp_region
  category     = "terraform"
  workspace_id = tfe_workspace.demo.id
}
