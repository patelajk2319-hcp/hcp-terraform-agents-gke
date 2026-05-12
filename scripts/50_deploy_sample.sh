#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/colours.sh"
source "${SCRIPT_DIR}/lib/env_check.sh"
source "${SCRIPT_DIR}/lib/auth_check.sh"

load_env "${SCRIPT_DIR}/../.env"
assert_gcp_auth

WI_PROVIDER="$(terraform -chdir="${SCRIPT_DIR}/../terraform/gke-cluster" output -raw workload_identity_provider_name)"
AGENT_SA="$(terraform -chdir="${SCRIPT_DIR}/../terraform/gke-cluster" output -raw hcp_terraform_agent_sa_email)"

cd "${SCRIPT_DIR}/../terraform/workspace-bootstrap"

step "Bootstrapping HCP Terraform project and workspace"
terraform init -upgrade
TFE_TOKEN="${HCP_TERRAFORM_TOKEN}" terraform apply \
  -var="hcp_terraform_organization=${HCP_TERRAFORM_ORGANIZATION}" \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -var="workload_identity_audience=${WORKLOAD_IDENTITY_AUDIENCE}" \
  -var="workload_identity_provider_name=${WI_PROVIDER}" \
  -var="agent_sa_email=${AGENT_SA}" \
  -auto-approve

success "Workspace bootstrap complete."
