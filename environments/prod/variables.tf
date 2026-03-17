variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "mypythonproject1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Networking
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "database_subnet_cidrs" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8000
}

variable "frontend_port" {
  description = "Frontend container port"
  type        = number
  default     = 4200
}

# RDS Configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "gamedb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17.6"
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for auto-scaling"
  type        = number
  default     = 100
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}

variable "multi_az" {
  description = "Enable Multi-AZ RDS deployment"
  type        = bool
  default     = true
}

variable "enable_secret_rotation" {
  description = "Enable Secrets Manager automatic rotation resources"
  type        = bool
  default     = false
}

# EKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "endpoint_public_access" {
  description = "Enable public access to EKS API endpoint"
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "EC2 instance types for managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Node capacity type: ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Node disk size in GB"
  type        = number
  default     = 20
}

variable "desired_node_count" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 5
}

variable "app_namespace" {
  description = "Kubernetes namespace for application pods"
  type        = string
  default     = "app"
}

variable "app_service_account" {
  description = "Kubernetes service account name for IRSA"
  type        = string
  default     = "app-sa"
}

# ALB Configuration
variable "health_check_path" {
  description = "ALB health check path"
  type        = string
  default     = "/health"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "alb_enforce_https_only" {
  description = "Enforce HTTPS-only ALB listeners"
  type        = bool
  default     = false
}

variable "alb_web_acl_arn" {
  description = "Optional WAFv2 Web ACL ARN to associate to ALB"
  type        = string
  default     = ""
}

# Security & JWT
variable "jwt_secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "jwt_algorithm" {
  description = "JWT algorithm"
  type        = string
  default     = "HS256"
}

variable "jwt_expire_minutes" {
  description = "JWT expiration time in minutes"
  type        = number
  default     = 60
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# ─── Helm System Add-ons ──────────────────────────────────────────────────────────

variable "alb_controller_chart_version" {
  description = "Helm chart version for AWS Load Balancer Controller"
  type        = string
  default     = "1.10.0"
}

variable "cluster_autoscaler_chart_version" {
  description = "Helm chart version for Cluster Autoscaler"
  type        = string
  default     = "9.46.0"
}

# ─── ArgoCD ──────────────────────────────────────────────────────────────────
variable "argocd_chart_version" {
  description = "Helm chart version for argo-cd"
  type        = string
  default     = "7.8.3"
}

variable "argocd_hostname" {
  description = "Hostname for the ArgoCD web UI"
  type        = string
  default     = "argocd.example.com"
}

variable "argocd_ingress_enabled" {
  description = "Enable ALB ingress for ArgoCD"
  type        = bool
  default     = true
}

variable "argocd_server_replicas" {
  description = "Number of ArgoCD server replicas (increase to 2+ for HA in prod)"
  type        = number
  default     = 1
}

variable "argocd_app_repo_url" {
  description = "GitOps repo URL for ArgoCD bootstrap Application (leave empty on first apply)"
  type        = string
  default     = ""
}

variable "argocd_app_revision" {
  description = "Git branch/tag for the bootstrap Application"
  type        = string
  default     = "main"
}

variable "argocd_app_path" {
  description = "Path in the repo containing Kubernetes manifests"
  type        = string
  default     = "k8s/overlay"
}

variable "argocd_create_app_project" {
  description = "Create an ArgoCD AppProject for this environment. Disable on first apply."
  type        = bool
  default     = false
}
