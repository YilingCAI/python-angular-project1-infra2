variable "project_name" {
  description = "Project name — used for ArgoCD AppProject and resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev / staging / prod)"
  type        = string
}

variable "argocd_chart_version" {
  description = "Helm chart version for argo-cd (chart, not app version)"
  type        = string
  default     = "7.8.3"
}

variable "argocd_hostname" {
  description = "Hostname for the ArgoCD web UI (e.g. argocd.dev.example.com)"
  type        = string
  default     = "argocd.example.com"
}

variable "ingress_enabled" {
  description = "Enable ALB ingress for ArgoCD server"
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS ingress (leave empty for HTTP)"
  type        = string
  default     = ""
}

variable "server_replicas" {
  description = "Number of ArgoCD server / repoServer / applicationSet replicas"
  type        = number
  default     = 1
}

# ─── App-of-apps bootstrap (optional) ───────────────────────────────────────
# Leave app_repo_url = "" on first apply (ArgoCD CRDs don't exist yet).
# Set it in a subsequent apply to bootstrap the GitOps application tree.

variable "app_repo_url" {
  description = "GitOps repository URL for the bootstrap Application (leave empty to skip)"
  type        = string
  default     = ""
}

variable "app_revision" {
  description = "Git branch / tag / commit for the bootstrap Application"
  type        = string
  default     = "main"
}

variable "app_path" {
  description = "Path within the repo containing Kubernetes manifests / Helm chart"
  type        = string
  default     = "k8s/overlay"
}

variable "app_namespace" {
  description = "Target namespace for the bootstrap Application"
  type        = string
  default     = "app"
}

# ─── AppProject ──────────────────────────────────────────────────────────────

variable "create_app_project" {
  description = "Create an ArgoCD AppProject scoped to this environment. Disable on first apply."
  type        = bool
  default     = false
}

variable "allowed_source_repos" {
  description = "Allowed source repositories for the AppProject"
  type        = list(string)
  default     = ["*"]
}
