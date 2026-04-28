#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/colours.sh
source "${SCRIPT_DIR}/lib/colours.sh"
# shellcheck source=lib/gke_context.sh
source "${SCRIPT_DIR}/lib/gke_context.sh"

ENV_FILE="${SCRIPT_DIR}/../.env"
if [[ ! -f "${ENV_FILE}" ]]; then
  error ".env file not found at ${ENV_FILE}. Copy .env.example and populate it."
  exit 1
fi
# shellcheck disable=SC1090
source "${ENV_FILE}"

warn "Destroying all resources in project '${GCP_PROJECT_ID}'."

get_gke_credentials "${GKE_CLUSTER_NAME}" "${GKE_REGION}" "${GCP_PROJECT_ID}" 2>/dev/null || true

step "Destroying workspace bootstrap"
cd "${SCRIPT_DIR}/../terraform/workspace-bootstrap"
terraform destroy \
  -var="hcp_terraform_token=${HCP_TERRAFORM_TOKEN}" \
  -var="hcp_terraform_organization=${HCP_TERRAFORM_ORGANIZATION}" \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -auto-approve || warn "Workspace bootstrap destroy failed (may already be removed)."

step "Destroying agent pools"
kubectl delete agentpool --all -n tfc-agents --timeout=60s 2>/dev/null || true
cd "${SCRIPT_DIR}/../terraform/agent-pools"
terraform destroy \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -var="hcp_terraform_token=${HCP_TERRAFORM_TOKEN}" \
  -var="hcp_terraform_organization=${HCP_TERRAFORM_ORGANIZATION}" \
  -auto-approve || warn "Agent pools destroy failed (may already be removed)."

step "Destroying HCP Terraform Operator"
cd "${SCRIPT_DIR}/../terraform/hcp-terraform-operator"
terraform destroy \
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
