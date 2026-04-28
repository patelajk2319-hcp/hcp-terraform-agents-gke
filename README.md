# HCP Terraform Agents on GKE

Deploy the HCP Terraform Operator v2 on a private GKE cluster. The operator manages `AgentPool` custom resources that run `tfc-agent` pods, enabling HCP Terraform to execute Terraform runs inside your GKE cluster using Workload Identity — no static credentials required.

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
task deploy:sample     # HCP Terraform project + workspace for the GCS demo
```

### 5. Run the Sample Workload

```bash
task run:sample
```

This triggers a CLI-driven Terraform run in HCP Terraform. The run is executed by a `tfc-agent` pod on GKE using Workload Identity to deploy a GCS bucket into your GCP project. Watch the agent pod appear in the cluster:

```bash
kubectl get pods -n tfc-agents -w
```

### 6. Verify

```bash
task verify
```

## Cleanup

```bash
task destroy
```

Destroys all resources in reverse order: workspace bootstrap → agent pools → operator → GKE cluster.

## Available Commands

```
task login           Authenticate with GCP and set application default credentials
task deploy:gke      Deploy the GKE cluster
task deploy:operator Deploy the HCP Terraform Operator onto the GKE cluster
task deploy:agents   Deploy HCP Terraform Agent Pools
task deploy:sample   Bootstrap the HCP Terraform project and workspace for the GCS bucket demo
task deploy:all      Deploy everything in order (GKE → Operator → Agents → Sample)
task run:sample      Trigger a CLI-driven run of the sample GCS bucket workspace on HCP Terraform
task verify          Verify the deployment health
task fmt             Run terraform fmt across all modules
task validate        Run terraform validate across all modules
task destroy         Destroy all resources
```

## Troubleshooting

### No agents visible in HCP Terraform UI

Expected — `minReplicas=0` means no pods run until a workspace queues a run. Once a run is queued the operator will scale up a pod within ~30 seconds.

### Agent pod fails to authenticate to GCP

Verify the Workload Identity binding is in place:

```bash
kubectl describe serviceaccount tfc-agent -n tfc-agents
```

The annotation `iam.gke.io/gcp-service-account` should reference the agent GSA. If missing, re-run `task deploy:agents`.

### kubectl context points to the wrong cluster

```bash
task login
```

Re-running login resets the gcloud project and ADC. Then re-run the failing deploy step.
