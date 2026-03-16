output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN (used for IRSA)"
  value       = module.eks.oidc_provider_arn
}

output "alb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = module.eks.alb_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler"
  value       = module.eks.cluster_autoscaler_role_arn
}

output "app_secrets_role_arn" {
  description = "IAM role ARN for app pods to access Secrets Manager"
  value       = module.eks.app_secrets_role_arn
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-dashboard"
}

output "argocd_url" {
  description = "ArgoCD web UI URL"
  value       = module.argocd.argocd_server_url
}

output "argocd_get_admin_password" {
  description = "kubectl command to retrieve ArgoCD initial admin password"
  value       = module.argocd.get_admin_password_cmd
}
