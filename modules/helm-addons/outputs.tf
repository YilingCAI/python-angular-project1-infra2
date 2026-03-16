output "alb_controller_release_status" {
  description = "Helm deployment status for AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.status
}

output "cluster_autoscaler_release_status" {
  description = "Helm deployment status for Cluster Autoscaler"
  value       = helm_release.cluster_autoscaler.status
}

output "secrets_store_csi_release_status" {
  description = "Helm deployment status for Secrets Store CSI Driver"
  value       = helm_release.secrets_store_csi.status
}

output "metrics_server_release_status" {
  description = "Helm deployment status for Metrics Server"
  value       = helm_release.metrics_server.status
}
