# HCP Terraform Agents on GKE

> **Disclaimer:** This repository is a demo environment only. It is not designed, tested, or hardened for production use. Do not use it to manage real workloads or sensitive infrastructure.

Deploy the HCP Terraform Operator v2 on a private GKE cluster. The operator manages `AgentPool` custom resources that run `tfc-agent` pods, enabling HCP Terraform to execute Terraform runs inside your GKE cluster.

## Scope

This repo is responsible for **GKE infrastructure and agent runtime only**:

| What lives here | What lives in [tf-hcp-wif](https://github.com/patelajk2319-hcp/tf-hcp-wif) |
|---|---|
| VPC, private GKE cluster, node pools, Cloud NAT | WIF pools and OIDC providers |
| GKE node service account (logs/metrics/images) | Per-app GCP service accounts (prod + nonprod) |
| HCP Terraform Operator (Helm) | WIF impersonation bindings and IAM |
| AgentPool CRDs (registers pools in HCP Terraform) | HCP Terraform projects, workspaces, variable sets |

## Prerequisites

### GCP Requirements
- Active GCP project with billing enabled
- APIs enabled: `container.googleapis.com`, `compute.googleapis.com`, `iam.googleapis.com`
- Owner or Editor IAM role on the project

### HCP Terraform Requirements
- HCP Terraform organisation (Plus plan or trial for self-hosted agents)
- Team API Token — Settings → Teams → \<team\> → Team API Token

### Required Tools

```bash
brew install terraform
brew install google-cloud-sdk
brew install kubectl
brew install go-task
```

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/patelajk2319-hcp/hcp-terraform-agents-gke.git
cd hcp-terraform-agents-gke
```

### 2. Create `.env` File

```bash
cp .env.example .env
```

Edit `.env` and populate:

```bash
# GCP
GCP_PROJECT_ID=your-gcp-project-id
GKE_REGION=europe-west2

# HCP Terraform
HCP_TERRAFORM_TOKEN=your-team-api-token
HCP_TERRAFORM_ORGANIZATION=your-org-name
```

### 3. Authenticate

```bash
task login
```

This runs `gcloud auth login`, sets the active project, and configures Application Default Credentials.

### 4. Deploy the Stack

```bash
task deploy:all
```

Or step-by-step:

```bash
task deploy:gke        # VPC, private GKE cluster, node pools, Cloud NAT
task deploy:operator   # HCP Terraform Operator via Helm
task deploy:agents     # non-prod and prod AgentPool custom resources
```

### 5. Wire up WIF and workspaces

Once the agent pools are registered in HCP Terraform, use [tf-hcp-wif](https://github.com/patelajk2319-hcp/tf-hcp-wif) to:
- Create the shared WIF pools (once per environment tier)
- Onboard each application (service accounts, workspaces, variable sets, IAM)

### 6. Verify

```bash
task verify
```

## Cleanup

```bash
task destroy
```

Destroys all resources in reverse order: agent pools → operator → GKE cluster.

> WIF pools, service accounts, and HCP Terraform workspaces are managed by [tf-hcp-wif](https://github.com/patelajk2319-hcp/tf-hcp-wif) and must be destroyed there.

## Available Commands

```
task login           Authenticate with GCP and set application default credentials
task deploy:gke      Deploy the GKE cluster
task deploy:operator Deploy the HCP Terraform Operator onto the GKE cluster
task deploy:agents   Deploy HCP Terraform Agent Pools
task deploy:all      Deploy everything in order (GKE → Operator → Agents)
task verify          Verify the deployment health
task destroy         Destroy all resources
```

## Troubleshooting

### No agents visible in HCP Terraform UI

Expected — `minReplicas=0` means no pods run until a workspace queues a run. Once a run is queued the operator will scale up a pod within ~30 seconds.

### Agent pod fails to authenticate to GCP

The WIF pool, OIDC provider, and service account impersonation bindings are managed in [tf-hcp-wif](https://github.com/patelajk2319-hcp/tf-hcp-wif). Verify those resources exist and the workspace variable set contains the correct `TFC_GCP_WORKLOAD_PROVIDER_NAME` and `TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL` values.

### kubectl context points to the wrong cluster

```bash
task login
```

Re-running login resets the gcloud project and ADC. Then re-run the failing deploy step.
