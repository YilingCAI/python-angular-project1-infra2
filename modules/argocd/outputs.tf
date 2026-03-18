output "namespace" {
  description = "Kubernetes namespace where ArgoCD is installed"
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "helm_release_status" {
  description = "Helm release status for ArgoCD"
  value       = helm_release.argocd.status
}

output "argocd_server_url" {
  description = "ArgoCD web UI URL"
  value       = var.ingress_enabled ? "http://${var.argocd_hostname}" : "http://localhost:8080 (port-forward)"
}

output "nip_io_instructions" {
  description = "Steps to set the real nip.io hostname after first apply"
  value       = <<-EOT
    After first apply, get the ALB IP:
      dig +short $(kubectl get ingress -n argocd -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}') | head -1

    Then set argocd_hostname in terraform.tfvars:
      argocd_hostname = "argocd.<IP>.nip.io"   # e.g. argocd.1.2.3.4.nip.io

    Re-run terraform apply. nip.io resolves to that IP with no DNS setup needed.
    Set GitHub secret ARGOCD_SERVER = argocd.<IP>.nip.io  (no http://)
    ArgoCD is served over HTTP (port 80) — workflow uses http:// for API calls.
  EOT
}

output "get_admin_password_cmd" {
  description = "kubectl command to retrieve the initial ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode"
}

output "bootstrap_app_name" {
  description = "Name of the bootstrap ArgoCD Application (empty if not created)"
  value       = var.app_repo_url != "" ? "${var.project_name}-apps" : ""
}
