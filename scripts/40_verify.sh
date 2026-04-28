#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/colors.sh
source "${SCRIPT_DIR}/lib/colors.sh"
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

step "Nodes"
kubectl get nodes -o wide

step "Operator"
kubectl get pods -n tfc-operator-system -o wide

step "Agent pools"
kubectl get agentpool -n tfc-agents 2>/dev/null || warn "No AgentPool resources found."

step "Agent pods"
kubectl get pods -n tfc-agents -o wide 2>/dev/null || warn "No agent pods running."

step "Operator logs (last 50 lines)"
OPERATOR_POD="$(kubectl get pods -n tfc-operator-system \
  -l app.kubernetes.io/name=hcp-terraform-operator \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

if [[ -n "${OPERATOR_POD}" ]]; then
  kubectl logs "${OPERATOR_POD}" -n tfc-operator-system --tail=50
else
  warn "Operator pod not found."
fi
