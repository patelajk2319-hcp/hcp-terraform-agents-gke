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

cd "${SCRIPT_DIR}/../terraform/hcp-terraform-operator"

step "Deploying HCP Terraform Operator"
terraform init -upgrade
terraform apply \
  -var="cluster_name=${GKE_CLUSTER_NAME}" \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -var="hcp_terraform_token=${HCP_TERRAFORM_TOKEN}" \
  -auto-approve

wait_for_pods "tfc-operator-system" "app.kubernetes.io/name=hcp-terraform-operator" 300
success "HCP Terraform Operator is ready."
