resource "random_id" "suffix" {
  byte_length = 4
}

# ── Networking ──────────────────────────────────────────────────────────────

resource "google_compute_network" "vpc" {
  name                    = "${local.cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${local.cluster_name}-subnet"
  network       = google_compute_network.vpc.id
  region        = var.gcp_region
  ip_cidr_range = "10.0.0.0/16"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }

  private_ip_google_access = true
}

# ── Node Service Account ──────────────────────────────────────────────────────
# Dedicated least-privilege SA for GKE nodes so you don't need the default Compute SA
# which has broad editor permissions. The 3 bindings below are the
# minimum required for node operation: ship logs, push metrics, pull images.

resource "google_service_account" "gke_nodes" {
  account_id   = "${local.cluster_name}-nodes"
  display_name = "GKE Node Service Account for ${local.cluster_name}"
}

resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_artifact_reader" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# ── GKE Cluster ──────────────────────────────────────────────────────────────

resource "google_container_cluster" "primary" {
  name     = local.cluster_name
  location = var.gcp_region

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true            # Nodes get private IPs only; egress via Cloud NAT
    enable_private_endpoint = false           # Kubernetes API remains publicly reachable via kubectl
    master_ipv4_cidr_block  = "172.16.0.0/28" # Dedicated /28 for control plane VPC peering — GKE requires exactly /28, cannot be changed after cluster creation
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  resource_labels = {
    managed-by  = "terraform"
    environment = "demo"
    purpose     = "hcp-terraform-agents"
  }

  deletion_protection = false
}

# ── System Node Pool ─────────────────────────────────────────────────────────

resource "google_container_node_pool" "system" {
  name     = "system"
  cluster  = google_container_cluster.primary.id
  location = var.gcp_region

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    machine_type    = "e2-standard-2"
    service_account = google_service_account.gke_nodes.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      managed-by  = "terraform"
      environment = "demo"
      purpose     = "hcp-terraform-agents"
      node-pool   = "system"
    }

    taint {
      key    = "node-role"
      value  = "system"
      effect = "NO_SCHEDULE"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ── Agent Node Pool ───────────────────────────────────────────────────────────

resource "google_container_node_pool" "agents" {
  name     = "agents"
  cluster  = google_container_cluster.primary.id
  location = var.gcp_region

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  node_config {
    machine_type    = "e2-standard-2"
    service_account = google_service_account.gke_nodes.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      managed-by  = "terraform"
      environment = "demo"
      purpose     = "hcp-terraform-agents"
      node-pool   = "agents"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ── Cloud NAT (egress for private nodes) ─────────────────────────────────────

resource "google_compute_router" "router" {
  name    = "${local.cluster_name}-router"
  region  = var.gcp_region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${local.cluster_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
