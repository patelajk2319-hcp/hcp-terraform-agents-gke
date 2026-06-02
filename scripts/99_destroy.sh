#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/colours.sh"
source "${SCRIPT_DIR}/lib/env_check.sh"
source "${SCRIPT_DIR}/lib/gke_context.sh"
source "${SCRIPT_DIR}/lib/auth_check.sh"

load_env "${SCRIPT_DIR}/../.env"
assert_gcp_auth

warn "Destroying all resources in project '${GCP_PROJECT_ID}'."

get_gke_credentials "${GKE_CLUSTER_NAME}" "${GKE_REGION}" "${GCP_PROJECT_ID}" 2>/dev/null || true

step "Destroying agent pools"
# Strip finalizers first so the delete doesn't block waiting for the operator.
for ap in $(kubectl get agentpool -n tfc-agents -o name 2>/dev/null || true); do
  kubectl patch "${ap}" -n tfc-agents --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
done
kubectl delete agentpool --all -n tfc-agents --timeout=60s 2>/dev/null || true
cd "${SCRIPT_DIR}/../terraform/agent-pools"
terraform destroy \
  -var="cluster_name=${GKE_CLUSTER_NAME}" \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -var="hcp_terraform_token=${HCP_TERRAFORM_TOKEN}" \
  -var="hcp_terraform_organization=${HCP_TERRAFORM_ORGANIZATION}" \
  -auto-approve || warn "Agent pools destroy failed (may already be removed)."

step "Destroying HCP Terraform Operator"
cd "${SCRIPT_DIR}/../terraform/hcp-terraform-operator"
terraform destroy \
  -var="cluster_name=${GKE_CLUSTER_NAME}" \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -var="hcp_terraform_token=${HCP_TERRAFORM_TOKEN}" \
  -auto-approve || warn "Operator destroy failed (may already be removed)."

step "Destroying GKE cluster"
cd "${SCRIPT_DIR}/../terraform/gke-cluster"
terraform destroy \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -auto-approve

success "All resources destroyed."
