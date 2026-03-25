# mypythonproject1-infra2

Professional infrastructure repository for mypythonproject1 using Terraform on AWS EKS.

## Project Overview

This repository provisions Kubernetes-first platform infrastructure for the application. It includes EKS, networking, ingress, database, and add-on integration components required for GitOps-based runtime operations.

It follows the same environment promotion philosophy as the application and other infrastructure repositories: dev, staging, then production.

## Architecture Flow

ALB/Ingress -> EKS workloads (frontend and backend) -> RDS PostgreSQL

## Architecture Diagram

```text
Internet Users
	|
	v
+------------------------------------+
| ALB / Kubernetes Ingress           |
|  - Public entrypoint               |
+----------------+-------------------+
		     |
		     v
+------------------------------------+
| EKS Cluster                         |
|                                    |
|  +----------------+                |
|  | Frontend Pods  |                |
|  +----------------+                |
|  +----------------+                |
|  | Backend Pods   |                |
|  +----------------+                |
+----------------+-------------------+
		     |
		     v
	   +------------------+
	   | AWS RDS Postgres |
	   +------------------+
```

## Provisioned Components

- VPC and subnet topology for cluster and data services
- EKS control plane and worker node infrastructure
- ALB-related ingress resources
- RDS PostgreSQL and supporting security resources
- Helm/Argo CD integration modules for platform add-ons

## Terraform Structure

### Modules

- modules/vpc: networking foundation (VPC, subnets, routing)
- modules/eks: cluster control plane and node-group related resources
- modules/alb: ingress/load-balancing integration resources
- modules/rds: PostgreSQL database and related access controls
- modules/helm-addons: cluster add-ons management components
- modules/argocd: Argo CD integration for GitOps operations

### Environment roots

Each root under environments/dev, environments/staging, and environments/prod typically includes:

- main.tf
- variables.tf
- outputs.tf
- providers.tf
- backend.hcl
- terraform.tfvars

## Repository Structure

| Path | Purpose |
|---|---|
| environments/dev/ | Development Terraform root |
| environments/staging/ | Staging Terraform root |
| environments/prod/ | Production Terraform root |
| modules/vpc/ | Network module |
| modules/eks/ | EKS cluster and worker resources |
| modules/alb/ | Ingress/load balancing resources |
| modules/rds/ | Database module |
| modules/helm-addons/ | Cluster add-on modules |
| modules/argocd/ | Argo CD integration resources |
| .github/workflows/ | Plan, apply, drift, and utility workflows |

## Environment Model

Each environment is managed independently with its own:

- backend.hcl
- terraform.tfvars
- provider and variable configuration

This keeps state and deployment risk isolated per stage.

## Deployment Steps

```bash
# Initialize Terraform
terraform -chdir=environments/staging init

# Plan
terraform -chdir=environments/staging plan

# Apply
terraform -chdir=environments/staging apply
```

## CI/CD Strategy

- Pull requests run speculative plans and policy checks.
- Merge flow executes ordered plan/apply with environment gates.
- Drift jobs run on schedule to detect unmanaged change.

## Security Model

- Ingress tier accepts internet traffic through ALB/Ingress only.
- Worker-node or pod network access is restricted by least-privilege SG/routing policy.
- Database access is limited to approved application network paths.
- CI/CD uses federated OIDC access instead of static long-lived AWS keys.

## Scaling Strategy

- Horizontal scaling is achieved through Kubernetes replica counts and autoscaling policies.
- Workload-level scaling allows frontend and backend to scale independently.
- Environment-specific node and resource profiles control cost versus resilience.
- Ingress distributes traffic across healthy pods and nodes.

## Local Validation

```bash
terraform -chdir=environments/dev init -backend=false
terraform -chdir=environments/dev validate

terraform -chdir=environments/staging init -backend=false
terraform -chdir=environments/staging validate

terraform -chdir=environments/prod init -backend=false
terraform -chdir=environments/prod validate
```

## Tech Stack

- Terraform
- AWS EKS
- Kubernetes
- AWS Application Load Balancer
- AWS RDS PostgreSQL
- Helm and Argo CD integration modules
- GitHub Actions

## Security and Operations Notes

- Use OIDC federation for CI access to AWS.
- Keep production changes behind approval-protected environments.
- Maintain strict separation between infrastructure code and GitOps application manifests.

## Future Improvements

- Add node-pool diversification and resilience testing.
- Add stricter policy-as-code controls in CI.
- Add advanced workload identity boundaries by namespace.
- Add proactive capacity planning with cost/performance dashboards.
