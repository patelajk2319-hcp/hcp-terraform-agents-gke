# ── Agent namespace ───────────────────────────────────────────────────────────

resource "kubernetes_namespace" "agents" {
  metadata {
    name = "tfc-agents"

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "hcp-terraform-agents"
    }
  }
}

# ── Workload Identity Kubernetes Service Account ──────────────────────────────

resource "kubernetes_service_account" "tfc_agent" {
  metadata {
    name      = "tfc-agent"
    namespace = kubernetes_namespace.agents.metadata[0].name

    annotations = {
      "iam.gke.io/gcp-service-account" = local.tfc_agent_service_account_email
    }
  }
}

# ── Agent pool API token secret ───────────────────────────────────────────────

resource "kubernetes_secret" "agent_token" {
  metadata {
    name      = "terraformrc"
    namespace = kubernetes_namespace.agents.metadata[0].name
  }

  data = {
    token = var.hcp_terraform_token
  }

  type = "Opaque"
}

# ── AgentPool custom resources ---
# ── When using the AgentPool CRD, Kubernetes manages the Agent Pools in HCP Terraform, including creating them ---

resource "kubernetes_manifest" "agent_pool" {
  for_each = local.agent_pools

  manifest = {
    apiVersion = "app.terraform.io/v1alpha2"
    kind       = "AgentPool"
    metadata = {
      name      = each.value.pool_name
      namespace = kubernetes_namespace.agents.metadata[0].name
    }
    spec = {
      organization = var.hcp_terraform_organization
      token = {
        secretKeyRef = {
          name = kubernetes_secret.agent_token.metadata[0].name
          key  = "token"
        }
      }
      name = each.value.pool_name
      agentTokens = [
        {
          name = each.value.token_name
        }
      ]
      agentDeployment = {
        replicas = null
        spec = {
          serviceAccountName = kubernetes_service_account.tfc_agent.metadata[0].name
          containers = [
            {
              name  = "tfc-agent"
              image = "hashicorp/tfc-agent:1.13.1"
              resources = {
                requests = {
                  cpu    = "250m"
                  memory = "256Mi"
                }
                limits = {
                  cpu    = "1000m"
                  memory = "512Mi"
                }
              }
            }
          ]
          nodeSelector = {
            "node-pool" = "agents"
          }
        }
      }
      autoscaling = {
        minReplicas = 0
        maxReplicas = 5
        cooldownPeriod = {
          scaleUpSeconds   = 30
          scaleDownSeconds = 300
        }
      }
    }
  }

  field_manager {
    force_conflicts = true
  }

  depends_on = [
    kubernetes_namespace.agents,
    kubernetes_secret.agent_token,
    kubernetes_service_account.tfc_agent,
  ]
}
