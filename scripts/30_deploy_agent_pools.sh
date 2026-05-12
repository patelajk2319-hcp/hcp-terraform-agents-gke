#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/colours.sh"
source "${SCRIPT_DIR}/lib/env_check.sh"
source "${SCRIPT_DIR}/lib/gke_context.sh"
source "${SCRIPT_DIR}/lib/auth_check.sh"

load_env "${SCRIPT_DIR}/../.env"
assert_gcp_auth

get_gke_credentials "${GKE_CLUSTER_NAME}" "${GKE_REGION}" "${GCP_PROJECT_ID}"

cd "${SCRIPT_DIR}/../terraform/agent-pools"

step "Deploying HCP Terraform Agent Pools"
terraform init -upgrade
terraform apply \
  -var="cluster_name=${GKE_CLUSTER_NAME}" \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -var="hcp_terraform_token=${HCP_TERRAFORM_TOKEN}" \
  -var="hcp_terraform_organization=${HCP_TERRAFORM_ORGANIZATION}" \
  -auto-approve

step "Waiting for AgentPools to be reconciled in Kubernetes"
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

# The AgentPool CRD creates the pool asynchronously in HCP Terraform.
# Poll the API until both pools are visible before the next step tries to look them up.
step "Waiting for agent pools to appear in HCP Terraform API"
for pool_name in "gke-agent-pool-non-prod" "gke-agent-pool-prod"; do
  elapsed=0
  until curl -sf \
    -H "Authorization: Bearer ${HCP_TERRAFORM_TOKEN}" \
    -H "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/organizations/${HCP_TERRAFORM_ORGANIZATION}/agent-pools" \
    | python3 -c "import sys,json; pools=json.load(sys.stdin)['data']; exit(0 if any(p['attributes']['name']=='${pool_name}' for p in pools) else 1)" \
    2>/dev/null; do
    if [[ "${elapsed}" -ge 180 ]]; then
      error "Timed out waiting for agent pool '${pool_name}' in HCP Terraform API."
      exit 1
    fi
    sleep 10
    elapsed=$(( elapsed + 10 ))
  done
  success "Agent pool '${pool_name}' is visible in HCP Terraform."
done
