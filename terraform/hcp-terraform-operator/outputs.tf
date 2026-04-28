output "operator_namespace" {
  description = "Namespace where the HCP Terraform Operator is deployed."
  value       = kubernetes_namespace.operator.metadata[0].name
}

output "operator_token_secret_name" {
  description = "Name of the Kubernetes secret holding the operator API token."
  value       = kubernetes_secret.operator_token.metadata[0].name
}
