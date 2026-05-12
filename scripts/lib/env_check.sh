#!/usr/bin/env bash
# Load and validate the .env file. Call load_env after sourcing this file.

load_env() {
  local env_file="${1}"
  if [[ ! -f "${env_file}" ]]; then
    error ".env file not found at ${env_file}. Copy .env.example and populate it."
    exit 1
  fi
  # shellcheck disable=SC1090
  source "${env_file}"
}
