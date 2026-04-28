output "agents_namespace" {
  description = "Kubernetes namespace where agent pools are deployed."
  value       = kubernetes_namespace.agents.metadata[0].name
}

output "agent_pool_names" {
  description = "Names of the deployed HCP Terraform agent pools."
  value       = { for k, v in local.agent_pools : k => v.pool_name }
}
