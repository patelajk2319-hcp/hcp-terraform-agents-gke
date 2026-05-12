locals {
  cluster_name = var.cluster_name

  agent_pools = {
    non-prod = {
      pool_name   = "gke-agent-pool-non-prod"
      token_names = ["gke-agent-token-non-prod-primary", "gke-agent-token-non-prod-secondary"]
    }
    prod = {
      pool_name   = "gke-agent-pool-prod"
      token_names = ["gke-agent-token-prod-primary", "gke-agent-token-prod-secondary"]
    }
  }
}
