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
```

## Environments

| Env | CIDR | Nodes | Capacity | Multi-AZ | Endpoint |
|-----|------|-------|----------|----------|---------|
| dev | 10.0.0.0/16 | 1–3 × t3.medium (SPOT) | dev | no | public |
| staging | 10.1.0.0/16 | 2–5 × t3.large | ON_DEMAND | yes | public |
| prod | 10.2.0.0/16 | 3–10 × t3.xlarge | ON_DEMAND | yes | private |
