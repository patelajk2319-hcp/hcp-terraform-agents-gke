# ── Namespace ─────────────────────────────────────────────────────────────────

resource "kubernetes_namespace" "operator" {
  metadata {
    name = "tfc-operator-system" # Follows Kubernetes Naming Convention - This can be called anything but name should be clear 

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "hcp-terraform-operator"
    }
  }
}

# ── API token secret — operator reads "terraformrc" at startup to authenticate ─
# ── The HCP Terraform Operator expects a Secret called "terraformrc" - So the secret MUST be called this
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

# ── Helm release — depends_on secret ensures it exists before operator starts ─

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
    kubernetes_secret.operator_token, # Secret must exist before we deploy the operator, else the operator will fail to install.
  ]
}
