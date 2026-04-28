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

cd "${SCRIPT_DIR}/../terraform/gke-cluster"

step "Deploying GKE cluster"
terraform init -upgrade
terraform apply \
  -var="gcp_project_id=${GCP_PROJECT_ID}" \
  -var="gcp_region=${GKE_REGION}" \
  -auto-approve

get_gke_credentials "${GKE_CLUSTER_NAME}" "${GKE_REGION}" "${GCP_PROJECT_ID}"

step "Waiting for nodes to be ready"
until kubectl get nodes --no-headers 2>/dev/null | grep -q .; do sleep 5; done
kubectl wait --for=condition=Ready nodes --all --timeout=300s

success "GKE cluster is ready."
