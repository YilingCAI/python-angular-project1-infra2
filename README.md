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
```

## Environments

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
