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

get_gke_credentials "${GKE_CLUSTER_NAME}" "${GKE_REGION}" "${GCP_PROJECT_ID}"

cd "${SCRIPT_DIR}/../terraform/agent-pools"

step "Deploying HCP Terraform Agent Pools"
terraform init -upgrade
terraform apply \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -var="hcp_terraform_token=${HCP_TERRAFORM_TOKEN}" \
  -var="hcp_terraform_organization=${HCP_TERRAFORM_ORGANIZATION}" \
  -auto-approve

step "Waiting for AgentPools to be reconciled"
for pool_name in "gke-agent-pool-non-prod" "gke-agent-pool-prod"; do
  elapsed=0
  until kubectl get agentpool "${pool_name}" -n tfc-agents &>/dev/null; do
    if [[ "${elapsed}" -ge 120 ]]; then
      error "Timed out waiting for AgentPool '${pool_name}'."
      exit 1
    fi
    sleep 5
    elapsed=$(( elapsed + 5 ))
  done
done

kubectl get agentpool -n tfc-agents
success "Agent pools are ready."
