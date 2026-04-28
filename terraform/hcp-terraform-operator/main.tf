# ── Operator namespace ────────────────────────────────────────────────────────

resource "kubernetes_namespace" "operator" {
  metadata {
    name = "tfc-operator-system"

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "hcp-terraform-operator"
    }
  }
}

# ── Operator API token secret ─────────────────────────────────────────────────

resource "kubernetes_secret" "operator_token" {
  metadata {
    name      = "terraformrc"
    namespace = kubernetes_namespace.operator.metadata[0].name
  }

  data = {
    token = var.hcp_terraform_token
  }

  type = "Opaque"
}

# ── HCP Terraform Operator Helm release ──────────────────────────────────────

resource "helm_release" "hcp_terraform_operator" {
  name       = "hcp-terraform-operator"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "hcp-terraform-operator"
  version    = "2.9.0"
  namespace  = kubernetes_namespace.operator.metadata[0].name

  values = [
    file("${path.module}/../../helm-chart/hcp-terraform-operator/values/operator-values.yaml")
  ]

  wait          = true
  wait_for_jobs = true
  timeout       = 600

  depends_on = [
    kubernetes_namespace.operator,
    kubernetes_secret.operator_token,
  ]
}
