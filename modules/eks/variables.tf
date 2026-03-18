variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for node groups"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (for ALB / cluster endpoint)"
  type        = list(string)
}

variable "eks_nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
  type        = string
}

variable "endpoint_public_access" {
  description = "Enable public access to EKS API endpoint (set false for prod)"
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type: ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Node disk size in GB"
  type        = number
  default     = 20
}

variable "desired_node_count" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "app_namespace" {
  description = "Kubernetes namespace for application pods"
  type        = string
  default     = "app"
}

variable "app_service_account" {
  description = "Kubernetes service account name used by app pods (for IRSA)"
  type        = string
  default     = "app-sa"
}

variable "secrets_arns" {
  description = "List of Secrets Manager ARNs the app pods are allowed to read"
  type        = list(string)
  default     = []
}

variable "kms_key_arns" {
  description = "List of KMS key ARNs used to decrypt secrets"
  type        = list(string)
  default     = []
}

variable "admin_iam_arns" {
  description = "IAM user or role ARNs granted AmazonEKSClusterAdminPolicy (cluster-admin). Use for human operators who need kubectl access."
  type        = list(string)
  default     = []
}
