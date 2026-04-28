locals {
  cluster_name                    = "hcp-terraform-agents"
  tfc_agent_service_account_email = "${local.cluster_name}-tfc-agent@${var.gcp_project_id}.iam.gserviceaccount.com"

  agent_pools = {
    non-prod = {
      pool_name  = "gke-agent-pool-non-prod"
      token_name = "gke-agent-token-non-prod"
    }
    prod = {
      pool_name  = "gke-agent-pool-prod"
      token_name = "gke-agent-token-prod"
    }
  }
}
