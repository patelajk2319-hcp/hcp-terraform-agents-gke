#!/usr/bin/env bash
# GKE_CLUSTER_NAME is set dynamically in .env by 10_deploy_gke.sh.

get_gke_credentials() {
  local cluster="${1}"
  local region="${2}"
  local project="${3}"

  local sdk_bin
  sdk_bin="$(gcloud info --format='value(installation.sdk_root)' 2>/dev/null)/bin"
  export PATH="${sdk_bin}:${PATH}"

  if ! command -v gke-gcloud-auth-plugin &>/dev/null; then
    info "Installing gke-gcloud-auth-plugin…"
    local gcloud_path
    gcloud_path="$(command -v gcloud)"
    if [[ "${gcloud_path}" == */Cellar/* || "${gcloud_path}" == */homebrew/* || "${gcloud_path}" == */Homebrew/* ]]; then
      brew install --quiet google-cloud-sdk
    else
      gcloud components install gke-gcloud-auth-plugin --quiet
    fi
    if ! command -v gke-gcloud-auth-plugin &>/dev/null; then
      error "gke-gcloud-auth-plugin not found. Install it and re-run."
      exit 1
    fi
  fi

  gcloud container clusters get-credentials "${cluster}" \
    --region "${region}" \
    --project "${project}"
}

wait_for_pods() {
  local namespace="${1}"
  local label_selector="${2}"
  local timeout_seconds="${3:-300}"

  info "Waiting for pods in '${namespace}' to be ready…"
  kubectl wait pods \
    -n "${namespace}" \
    -l "${label_selector}" \
    --for=condition=Ready \
    --timeout="${timeout_seconds}s"
}
