variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID — required by AWS Load Balancer Controller"
  type        = string
}

variable "alb_controller_role_arn" {
  description = "IRSA role ARN for AWS Load Balancer Controller"
  type        = string
}

variable "cluster_autoscaler_role_arn" {
  description = "IRSA role ARN for Cluster Autoscaler"
  type        = string
}

# ─── Chart versions — pin these in production ────────────────────────────────

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

variable "secrets_store_csi_chart_version" {
  description = "Helm chart version for Secrets Store CSI Driver"
  type        = string
  default     = "1.4.8"
}

variable "secrets_provider_aws_chart_version" {
  description = "Helm chart version for AWS Secrets Manager CSI provider"
  type        = string
  default     = "0.3.9"
}

variable "metrics_server_chart_version" {
  description = "Helm chart version for Metrics Server"
  type        = string
  default     = "3.12.1"
}
