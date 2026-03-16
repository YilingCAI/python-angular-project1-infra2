/**
 * Main Terraform Configuration – EKS
 * Orchestrates all modules: network, RDS, ALB, and EKS
 */

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
  }

  # Partial S3 backend configuration — all values injected at `terraform init` time
  # via -backend-config flags in CI (backend.hcl or CI workflow env vars).
  backend "s3" {
    encrypt = true
  }
}

data "aws_caller_identity" "current" {}

locals {
  cluster_name = "${var.project_name}-eks"
}

# Networking Module
module "network" {
  source = "../../modules/vpc"

  project_name          = var.project_name
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  app_port              = var.app_port
  cluster_name          = local.cluster_name
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project_name             = var.project_name
  database_subnet_ids      = module.network.database_subnet_ids
  rds_security_group_id    = module.network.rds_security_group_id
  db_name                  = var.db_name
  db_username              = var.db_username
  db_engine_version        = var.db_engine_version
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  backup_retention_days    = var.backup_retention_days
  multi_az                 = var.multi_az
  log_retention_days       = var.log_retention_days
  enable_secret_rotation   = var.enable_secret_rotation
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project_name          = var.project_name
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
  app_port              = var.app_port
  frontend_port         = var.frontend_port
  health_check_path     = var.health_check_path
  certificate_arn       = var.certificate_arn
  enforce_https_only    = var.alb_enforce_https_only
  web_acl_arn           = var.alb_web_acl_arn
}

# JWT Secret in Secrets Manager (referenced by EKS pods via IRSA)
#checkov:skip=CKV2_AWS_57:Rotation is managed externally due application-specific rotation workflow.
resource "aws_secretsmanager_secret" "jwt_secret" {
  name_prefix             = "${var.project_name}-jwt-secret-"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.secrets.id

  tags = {
    Name = "${var.project_name}-jwt-secret"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
    JWT_SECRET_KEY     = var.jwt_secret_key
    JWT_ALGORITHM      = var.jwt_algorithm
    JWT_EXPIRE_MINUTES = var.jwt_expire_minutes
  })
}

# KMS Key for application secrets
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-secrets-key"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# KMS Key Policy — grants EKS app IRSA role decrypt access (CKV_AWS_33)
resource "aws_kms_key_policy" "secrets" {
  key_id = aws_kms_key.secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager to use the key"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "Allow EKS app IRSA role to decrypt secrets"
        Effect = "Allow"
        Principal = {
          AWS = module.eks.app_secrets_role_arn
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  project_name                = var.project_name
  environment                 = var.environment
  cluster_name                = local.cluster_name
  kubernetes_version          = var.kubernetes_version
  vpc_id                      = module.network.vpc_id
  private_subnet_ids          = module.network.private_subnet_ids
  public_subnet_ids           = module.network.public_subnet_ids
  eks_nodes_security_group_id = module.network.eks_nodes_security_group_id
  endpoint_public_access      = var.endpoint_public_access
  node_instance_types         = var.node_instance_types
  node_capacity_type          = var.node_capacity_type
  node_disk_size              = var.node_disk_size
  desired_node_count          = var.desired_node_count
  min_node_count              = var.min_node_count
  max_node_count              = var.max_node_count
  log_retention_days          = var.log_retention_days
  app_namespace               = var.app_namespace
  app_service_account         = var.app_service_account

  secrets_arns = [
    module.rds.secret_arn,
    aws_secretsmanager_secret.jwt_secret.arn,
  ]
  kms_key_arns = [
    aws_kms_key.secrets.arn,
    module.rds.kms_key_arn,
  ]

  depends_on = [module.alb]
}

# ─── Helm System Add-ons ──────────────────────────────────────────────────────
# Installs: AWS LB Controller, Cluster Autoscaler, Secrets Store CSI, Metrics Server
module "helm_addons" {
  source = "../../modules/helm-addons"

  cluster_name                = module.eks.cluster_name
  aws_region                  = var.aws_region
  vpc_id                      = module.network.vpc_id
  alb_controller_role_arn     = module.eks.alb_controller_role_arn
  cluster_autoscaler_role_arn = module.eks.cluster_autoscaler_role_arn

  alb_controller_chart_version     = var.alb_controller_chart_version
  cluster_autoscaler_chart_version = var.cluster_autoscaler_chart_version

  depends_on = [module.eks]
}

# ─── ArgoCD ──────────────────────────────────────────────────────────────────
# GitOps continuous delivery for Kubernetes workloads
module "argocd" {
  source = "../../modules/argocd"

  project_name         = var.project_name
  environment          = var.environment
  argocd_hostname      = var.argocd_hostname
  ingress_enabled      = var.argocd_ingress_enabled
  certificate_arn      = var.certificate_arn
  server_replicas      = var.argocd_server_replicas
  argocd_chart_version = var.argocd_chart_version

  # Bootstrap Application — leave empty on first apply; set after ArgoCD is running
  app_repo_url       = var.argocd_app_repo_url
  app_revision       = var.argocd_app_revision
  app_path           = var.argocd_app_path
  app_namespace      = var.app_namespace
  create_app_project = var.argocd_create_app_project

  depends_on = [module.helm_addons]
}

# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", local.cluster_name, { stat = "Average" }],
            [".", "node_memory_utilization", "ClusterName", local.cluster_name, { stat = "Average" }],
            ["AWS/RDS", "CPUUtilization", { stat = "Average" }],
            [".", "DatabaseConnections", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Infrastructure Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query  = "fields @timestamp, @message | stats count() by bin(5m)"
          region = var.aws_region
          title  = "Log Insights"
        }
      }
    ]
  })
}
