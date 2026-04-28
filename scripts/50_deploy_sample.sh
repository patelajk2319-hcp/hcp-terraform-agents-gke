#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/colors.sh
source "${SCRIPT_DIR}/lib/colors.sh"

ENV_FILE="${SCRIPT_DIR}/../.env"
if [[ ! -f "${ENV_FILE}" ]]; then
  error ".env file not found at ${ENV_FILE}. Copy .env.example and populate it."
  exit 1
fi
# shellcheck disable=SC1090
source "${ENV_FILE}"

cd "${SCRIPT_DIR}/../terraform/workspace-bootstrap"

step "Bootstrapping HCP Terraform project and workspace"
terraform init -upgrade
terraform apply \
  -var="hcp_terraform_token=${HCP_TERRAFORM_TOKEN}" \
  -var="hcp_terraform_organization=${HCP_TERRAFORM_ORGANIZATION}" \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -auto-approve

success "Workspace ready — run 'task run:sample' to trigger a run on the GKE agent."
