terraform {
  required_version = ">= 1.5.0"

  cloud {
    # Resolved at runtime from TF_CLOUD_ORGANIZATION and TF_WORKSPACE env vars.
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.44"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
