output "namespace" {
  description = "Kubernetes namespace where ArgoCD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "helm_release_status" {
  description = "Helm release status for ArgoCD"
  value       = helm_release.argocd.status
}

output "argocd_server_url" {
  description = "ArgoCD web UI URL (hostname-based)"
  value       = var.ingress_enabled ? "https://${var.argocd_hostname}" : "http://localhost:8080 (port-forward)"
}

output "get_admin_password_cmd" {
  description = "kubectl command to retrieve the initial ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode"
}

output "bootstrap_app_name" {
  description = "Name of the bootstrap ArgoCD Application (empty if not created)"
  value       = var.app_repo_url != "" ? "${var.project_name}-apps" : ""
}
