<<<<<<< HEAD
# mypythonproject1-infra2 — EKS Infrastructure

Terraform infrastructure for **mypythonproject1** running on **AWS EKS** (Elastic Kubernetes Service) with managed node groups.

This repository is a modernised replacement of `mypythonproject1-infra` (ECS/Fargate) and uses the same CI/CD pipeline with GitHub Actions + OIDC, but replaces ECS/Fargate with an EKS cluster.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  GitHub Actions CI/CD                │
│  OIDC → GitHubActionsRoleEKS → Terraform apply      │
└───────────────────┬─────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────┐
│                    AWS VPC                           │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  Public Subnets (ALB, NAT Gateway)           │   │
│  └──────────────┬───────────────────────────────┘   │
│                 │                                    │
│  ┌──────────────▼───────────────────────────────┐   │
│  │  Private Subnets (EKS Nodes)                 │   │
│  │                                              │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │  EKS Managed Node Group                │  │   │
│  │  │  • AWS Load Balancer Controller (IRSA) │  │   │
│  │  │  • Cluster Autoscaler (IRSA)           │  │   │
│  │  │  • Secrets Store CSI Driver (IRSA)     │  │   │
│  │  │  • Backend pods (namespace: app)       │  │   │
│  │  │  • Frontend pods (namespace: app)      │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  Database Subnets (RDS PostgreSQL)           │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

## Key differences from infra1 (ECS)

| Component | infra1 (ECS) | infra2 (EKS) |
|-----------|-------------|-------------|
| Compute | ECS Fargate tasks | EKS managed node groups |
| IAM access | ECS task execution roles | IRSA (IAM Roles for Service Accounts) |
| App secrets | ECS secrets injection | Secrets Store CSI Driver + IRSA |
| Scaling | ECS Application Auto Scaling | Kubernetes HPA + Cluster Autoscaler |
| Load balancing | ECS → ALB target groups | AWS Load Balancer Controller (Ingress) |
| State buckets | `mypythonproject1-tfstate-*` | `mypythonproject1-eks-tfstate-*` |
| GitHub IAM role | `GitHubActionsRole` | `GitHubActionsRoleEKS` |

## Repository Structure

```
├── bootstrap/               # One-time setup: S3 state buckets, ECR, OIDC, IAM role
│   ├── main.tf
│   ├── variables.tf
│   ├── provider.tf
│   └── env/
│       └── bootstrap.tfvars
├── modules/
│   ├── vpc/                 # VPC, subnets (with EKS tags), NAT, security groups
│   ├── eks/                 # EKS cluster, node groups, IRSA roles, add-ons
│   ├── rds/                 # RDS PostgreSQL with Secrets Manager + KMS
│   └── alb/                 # ALB, target groups, listener rules
├── environments/
│   ├── dev/                 # Development (SPOT nodes, single NAT, public endpoint)
│   ├── staging/             # Staging (ON_DEMAND, Multi-AZ, HA)
│   └── prod/                # Production (private endpoint, 3 AZs, deletion protection)
└── .github/
    ├── workflows/           # CI/CD: drift detection, plan, apply
    └── actions/             # Reusable composite actions (init, validate, plan)
```

## Prerequisites

- Terraform >= 1.5
- AWS CLI v2 configured
- `kubectl` + `helm` (for post-deploy Kubernetes configuration)
- GitHub repository secrets (see below)

## Bootstrap (first-time setup)

```bash
# Copy and fill in AWS credentials
cp .aws.local.env.example .aws.local.env
# Edit .aws.local.env with your credentials

# Run bootstrap to create S3 buckets, ECR repos, OIDC provider, IAM role
make bootstrap-apply
```

## GitHub Repository Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_OIDC_ROLE_ARN` | ARN of `GitHubActionsRoleEKS` role (output from bootstrap) |
| `TERRAFORM_STATE_BUCKET` | State bucket name per environment (e.g. `mypythonproject1-eks-tfstate-dev`) |
| `TF_VAR_JWT_SECRET_KEY` | JWT secret key for the application |
| `INFRACOST_API_KEY` | (optional) Infracost API key for cost estimation in PRs |

## Post-deployment: Install Kubernetes Add-ons

After `terraform apply`, install the required Helm charts:

```bash
# Configure kubectl
aws eks update-kubeconfig --name mypythonproject1-dev-eks --region us-east-1

# AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=mypythonproject1-dev-eks \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<alb_controller_role_arn>

# Cluster Autoscaler
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  -n kube-system \
  --set autoDiscovery.clusterName=mypythonproject1-dev-eks \
  --set rbac.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<cluster_autoscaler_role_arn>

# Secrets Store CSI Driver + AWS provider
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver -n kube-system
helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
helm install secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws -n kube-system
=======
# mypythonproject1-infra2

Terraform infrastructure for mypythonproject1 on AWS EKS.

This repository provisions and operates:
- VPC networking (public/private/database subnets)
- EKS cluster and managed node groups
- ALB ingress pathing via AWS Load Balancer Controller
- RDS PostgreSQL and related secrets/KMS
- Argo CD and Kubernetes add-ons via Helm
- Terraform remote state and CI IAM/OIDC bootstrap resources

## Terraform origin code

This repository was derived from the earlier ECS-based infrastructure repository and then reworked for EKS-first operations.

Source lineage:
- Previous baseline: ECS/Fargate architecture and workflow patterns
- Current target: EKS cluster, IRSA, Helm add-ons, Argo CD, Kubernetes-native operations

What was reused conceptually:
- Multi-environment promotion strategy (dev -> staging -> prod)
- GitHub Actions reusable workflow approach
- OIDC-based CI authentication into AWS
- Terraform module and environment structure style

What is now different in infra2:
- Compute moved from ECS tasks to EKS managed node groups
- App runtime is Kubernetes workloads rather than ECS services
- Add-ons are deployed via Helm modules
- Bootstrap state buckets use EKS naming conventions

Note:
- There is no runtime link between infra1 and infra2. They are separate Terraform roots and separate state backends.
- Changes in infra1 do not automatically propagate to infra2.

## Repository layout

```text
.
├── bootstrap/
│   ├── env/
│   │   └── bootstrap.tfvars
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── variables.tf
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   ├── alb/
│   ├── helm-addons/
│   └── argocd/
├── .github/workflows/
│   ├── terraform-plan-speculative.yml
│   ├── terraform-plan-apply.yml
│   ├── terraform-drift.yml
│   ├── terraform-plan-reusable.yml
│   └── terraform-apply-reusable.yml
├── .github/actions/
│   ├── terraform-setup-common/
│   │   └── action.yml
│   └── terraform-plan-common/
│       └── action.yml
└── Makefile
>>>>>>> feature/init
```

## Environments

<<<<<<< HEAD
| Env | CIDR | Nodes | Capacity | Multi-AZ | Endpoint |
|-----|------|-------|----------|----------|---------|
| dev | 10.0.0.0/16 | 1–3 × t3.medium (SPOT) | dev | no | public |
| staging | 10.1.0.0/16 | 2–5 × t3.large | ON_DEMAND | yes | public |
| prod | 10.2.0.0/16 | 3–10 × t3.xlarge | ON_DEMAND | yes | private |
=======
- dev: lower-cost defaults, fast iteration
- staging: pre-production validation
- prod: production controls and approvals

Each environment has its own Terraform root under environments/<env> with dedicated backend settings.

## State and locking

Terraform remote state is stored in S3 with versioning enabled and lockfile usage enabled.

Expected state bucket naming (from bootstrap tfvars):
- dev: mypythonproject1-tfstate-eks-dev
- staging: mypythonproject1-tfstate-eks-staging
- prod: mypythonproject1-tfstate-eks-prod

Typical backend.hcl values:

```hcl
bucket       = "<env-state-bucket>"
key          = "<env>/terraform.tfstate"
region       = "us-east-1"
use_lockfile = true
encrypt      = true
```

## Bootstrap

Bootstrap creates shared resources used by all environments:
- State buckets (S3 + versioning + encryption + public access block)
- ECR repositories
- GitHub OIDC provider
- GitHub Actions IAM role and policy

Configuration file:
- bootstrap/env/bootstrap.tfvars

Important current setting example:
- github_actions_role_name = "GitHubActionsRole"

Run bootstrap from repo root:

```bash
make bootstrap-init
make bootstrap-plan
make bootstrap-apply
```

Best effort import of pre-existing bootstrap resources:

```bash
make bootstrap-import-existing
```

## Local prerequisites

- Terraform >= 1.5
- AWS CLI v2
- Valid AWS credentials or AWS SSO session

If using local credential file:

```bash
cp .aws.local.env.example .aws.local.env
# then edit .aws.local.env
```

## CI/CD workflows

Top-level workflows:
- .github/workflows/terraform-plan-speculative.yml
- .github/workflows/terraform-plan-apply.yml
- .github/workflows/terraform-drift.yml

Reusable workflows:
- .github/workflows/terraform-plan-reusable.yml
- .github/workflows/terraform-apply-reusable.yml

Composite actions:
- .github/actions/terraform-setup-common/action.yml
- .github/actions/terraform-plan-common/action.yml

### PR validation flow

terraform-plan-speculative.yml runs speculative plans on pull requests:
1. plan-dev
2. plan-staging
3. plan-prod

Behavior:
- Local backend override for speculative planning
- Security checks enabled
- Optional Infracost support
- PR plan comments supported

### Promotion flow (main)

terraform-plan-apply.yml promotes in order:
1. plan dev -> apply dev
2. plan staging -> apply staging
3. plan prod -> apply prod

Triggers:
- push to main for Terraform path changes
- manual workflow_dispatch
- workflow_run after successful Terraform Plan Speculative

Safety controls:
- Apply consumes saved plan artifacts from plan stage
- Drift check executed before apply in apply reusable workflow
- Default behavior aborts apply on drift
- Dev manual override exists for drift continuation
- Production apply is gated by GitHub Environment approval

### Drift workflow

terraform-drift.yml runs dedicated drift detection:
- scheduled nightly run
- manual run by environment (dev/staging/prod/all)
- fails job when drift is detected

## Required GitHub configuration

Repository variables:
- AWS_REGION

Repository/environment secrets:
- AWS_OIDC_ROLE_ARN
- TERRAFORM_STATE_BUCKET
- JWT_SECRET_KEY
- INFRACOST_API_KEY (optional)

GitHub Environments:
- dev
- staging
- prod

Recommended protections:
- required reviewers for prod (and optionally staging)
- least-privilege IAM role permissions per environment

## Local operations

Example per-environment execution:

```bash
cd environments/dev
terraform init -reconfigure -backend-config=backend.hcl
terraform plan
terraform apply
```

If you only need provider/module download without backend access:

```bash
terraform init -backend=false
```

## Troubleshooting

### Backend init says region or value is missing

Cause:
- backend block is partial by design and needs backend.hcl or backend-config flags

Fix:

```bash
terraform init -reconfigure -backend-config=backend.hcl
```

### InvalidClientTokenId during init/plan/apply

Cause:
- expired or invalid AWS credentials/session

Fix:
- refresh credentials (for example with AWS SSO login)
- verify with aws sts get-caller-identity

### Drift detected but no console change made

Common causes:
- code defaults changed between module versions
- resource ownership moved across modules without state migration
- provider behavior differences after upgrades

Recommended approach:
- inspect exact attributes in plan
- avoid blind apply in prod
- use moved blocks or terraform state mv when ownership intentionally changes
>>>>>>> feature/init
