/**
 * ArgoCD Module
 *
 * Installs ArgoCD via Helm (argo/argo-cd) and configures it for GitOps.
 *
 * Features:
 *   - ArgoCD server with AWS ALB ingress (when ingress_enabled = true)
 *   - TLS terminated at ALB; ArgoCD runs plain HTTP internally
 *   - AppProject scoped to this environment
 *   - Optional bootstrap Application (app-of-apps pattern)
 *
 * Two-phase apply:
 *   The optional bootstrap Application (var.app_repo_url != "") creates an
 *   ArgoCD 'Application' CRD resource via kubernetes_manifest.  On a fresh
 *   cluster, ArgoCD CRDs do not exist until after the first helm_release apply.
 *   Leave app_repo_url = "" (default) on first apply; set it in a subsequent
 *   apply once ArgoCD is running.
 *
 * Retrieve initial admin password after deploy:
 *   kubectl -n argocd get secret argocd-initial-admin-secret \
 *     -o jsonpath='{.data.password}' | base64 --decode
 */

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

locals {
  # ALB ingress annotations — build set based on whether a cert ARN is provided
  listen_ports_https = jsonencode([{ HTTPS = 443 }])
  listen_ports_http  = jsonencode([{ HTTP = 80 }])

  ssl_annotations = var.certificate_arn != "" ? {
    "alb.ingress.kubernetes.io/certificate-arn" = var.certificate_arn
    "alb.ingress.kubernetes.io/ssl-policy"      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  } : {}

  alb_annotations = merge(
    {
      "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"  = "ip"
      "alb.ingress.kubernetes.io/group.name"   = "${var.project_name}-argocd"
      "alb.ingress.kubernetes.io/listen-ports" = var.certificate_arn != "" ? local.listen_ports_https : local.listen_ports_http
    },
    local.ssl_annotations
  )

  # Full Helm values map — encoded to YAML string for helm_release
  helm_values = {
    global = {
      domain = var.argocd_hostname
    }

    configs = {
      params = {
        # ArgoCD runs plain HTTP; TLS is terminated at the ALB
        "server.insecure" = "true"
      }
      cm = {
        "admin.enabled"                      = "true"
        "application.resourceTrackingMethod" = "annotation"
        "timeout.reconciliation"             = "180s"
        "accounts.admin"                     = "login,apiKey"
      }
      rbac = {
        # Default to read-only; promote users/groups via RBAC policies
        "policy.default" = "role:readonly"
      }
    }

    server = {
      replicas = var.server_replicas

      ingress = {
        enabled          = var.ingress_enabled
        ingressClassName = "alb"
        annotations      = local.alb_annotations
        hosts            = [var.argocd_hostname]
      }

      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
    }

    repoServer = {
      replicas = var.server_replicas

      resources = {
        requests = { cpu = "100m", memory = "256Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
    }

    applicationSet = {
      replicas = var.server_replicas
    }

    redis = {
      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
        limits   = { cpu = "200m", memory = "128Mi" }
      }
    }
  }
}

# ─── Namespace ───────────────────────────────────────────────────────────────
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"

    labels = {
      "app.kubernetes.io/managed-by" = "Terraform"
      environment                    = var.environment
    }
  }
}

# ─── ArgoCD Helm Release ─────────────────────────────────────────────────────
resource "helm_release" "argocd" {
  name            = "argocd"
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argo-cd"
  version         = var.argocd_chart_version
  namespace       = kubernetes_namespace_v1.argocd.metadata[0].name
  atomic          = true
  cleanup_on_fail = true
  timeout         = 600
  wait            = true
  wait_for_jobs   = true

  values = [yamlencode(local.helm_values)]

  depends_on = [kubernetes_namespace_v1.argocd]
}

# ─── ArgoCD AppProject ────────────────────────────────────────────────────────
# Scopes allowed source repos and target namespaces for this environment.
# kubectl_manifest is used instead of kubernetes_manifest so that Terraform does
# not validate the CRD against the API server at plan time (the CRD only exists
# after helm_release.argocd runs).
resource "kubectl_manifest" "app_project" {
  count = var.create_app_project ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = var.project_name
      namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    }
    spec = {
      description = "${var.project_name} — ${var.environment}"
      sourceRepos = var.allowed_source_repos
      destinations = [
        {
          namespace = "*"
          server    = "https://kubernetes.default.svc"
        }
      ]
      clusterResourceWhitelist = [
        { group = "*", kind = "*" }
      ]
      namespaceResourceWhitelist = [
        { group = "*", kind = "*" }
      ]
    }
  })

  depends_on = [helm_release.argocd]
}

# ─── Bootstrap Application (app-of-apps) ─────────────────────────────────────
# Points ArgoCD at the application GitOps directory.
# Only created when app_repo_url is set (leave empty on first apply).
# kubectl_manifest is used instead of kubernetes_manifest so that Terraform does
# not validate the CRD against the API server at plan time.
resource "kubectl_manifest" "bootstrap_app" {
  count = var.app_repo_url != "" ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = "${var.project_name}-apps"
      namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
      labels = {
        environment = var.environment
      }
    }
    spec = {
      project = var.create_app_project ? var.project_name : "default"
      source = {
        repoURL        = var.app_repo_url
        targetRevision = var.app_revision
        path           = var.app_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.app_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "ServerSideApply=true",
        ]
      }
    }
  })

  depends_on = [
    helm_release.argocd,
    kubectl_manifest.app_project,
  ]
}
