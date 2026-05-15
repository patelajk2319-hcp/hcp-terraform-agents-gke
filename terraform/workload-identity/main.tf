# ── HCP Terraform Workload Identity ──────────────────────────────────────────

resource "google_iam_workload_identity_pool" "hcp_terraform" {
  workload_identity_pool_id = "${var.cluster_name}-hcp-tf"
  display_name              = "HCP Terraform agents"
}

resource "google_iam_workload_identity_pool_provider" "hcp_terraform" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.hcp_terraform.workload_identity_pool_id
  workload_identity_pool_provider_id = "hcp-terraform"
  display_name                       = "HCP Terraform OIDC"

  oidc {
    issuer_uri = "https://app.terraform.io"
  }

  # Restrict to tokens issued for this org only — prevents any other HCP Terraform org from federating through this pool.
  attribute_condition = "assertion.terraform_organization_id == \"${var.hcp_terraform_organization_id}\""

  attribute_mapping = {
    "google.subject"                      = "assertion.sub"
    "attribute.terraform_run_phase"       = "assertion.terraform_run_phase"
    "attribute.terraform_workspace_id"    = "assertion.terraform_workspace_id"
    "attribute.terraform_organization_id" = "assertion.terraform_organization_id" // blocking tokens from other orgs.
  }
}

# ── HCP Terraform Agent Service Account ──────────────────────────────────────
# Dedicated SA that HCP Terraform agent runs impersonate via WIF.
# Grant permissions to this SA; the WIF principal set is allowed to impersonate it.

resource "google_service_account" "hcp_terraform_agent" {
  account_id   = "${var.cluster_name}-agent-sa"
  display_name = "HCP Terraform Agent SA for ${var.cluster_name}"
}

# Give storage admin to the account as can't create projects in my GCP account.
resource "google_project_iam_member" "hcp_terraform_agent_storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.hcp_terraform_agent.email}"
}

# Allow any agent run from this org to impersonate the agent SA.
resource "google_service_account_iam_member" "hcp_terraform_wif_impersonation" {
  service_account_id = google_service_account.hcp_terraform_agent.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.hcp_terraform.name}/attribute.terraform_organization_id/${var.hcp_terraform_organization_id}"
}
