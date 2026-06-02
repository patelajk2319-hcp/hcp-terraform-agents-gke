#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/colours.sh"
source "${SCRIPT_DIR}/lib/env_check.sh"
source "${SCRIPT_DIR}/lib/gke_context.sh"
source "${SCRIPT_DIR}/lib/auth_check.sh"

load_env "${SCRIPT_DIR}/../.env"
assert_gcp_auth

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

step "Writing cluster outputs to .env"
CLUSTER_NAME="$(terraform output -raw cluster_name)"
ENV_FILE="${SCRIPT_DIR}/../.env"

_upsert_env() {
  local key="${1}" value="${2}" file="${3}"
  local tmp
  tmp="$(mktemp)"
  if grep -q "^${key}=" "${file}"; then
    sed "s|^${key}=.*|${key}=${value}|" "${file}" > "${tmp}"
  else
    cp "${file}" "${tmp}"
    printf '\n%s=%s\n' "${key}" "${value}" >> "${tmp}"
  fi
  mv "${tmp}" "${file}"
}

_upsert_env "GKE_CLUSTER_NAME" "${CLUSTER_NAME}" "${ENV_FILE}"

success "GKE cluster is ready."
