#!/usr/bin/env bash
# Verify GCP application-default credentials are valid before running any
# Terraform or gcloud commands. Call assert_gcp_auth after sourcing this file.

assert_gcp_auth() {
  if ! gcloud auth application-default print-access-token &>/dev/null; then
    error "GCP credentials are missing or expired."
    error "Run:  task login"
    exit 1
  fi
  success "GCP credentials are valid."
}
