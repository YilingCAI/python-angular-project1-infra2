/**
 * Helm System Add-ons Module
 *
 * Installs essential Kubernetes system components via Helm.
 * This replaces the manual post-deployment steps previously described in README.
 *
 * Components:
 *   - AWS Load Balancer Controller  — Ingress → ALB/NLB (via IRSA)
 *   - Cluster Autoscaler            — Managed node-group auto-scaling (via IRSA)
 *   - Secrets Store CSI Driver      — Mount AWS Secrets Manager secrets as files/envvars
 *   - AWS Secrets Manager provider  — CSI provider for AWS
 *   - Metrics Server                — Required by Kubernetes HPA
 */

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }
}

# ─── AWS Load Balancer Controller ────────────────────────────────────────────
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = var.alb_controller_chart_version
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 600

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    # Bind the service account to the IRSA role so the controller can manage ALBs
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = var.alb_controller_role_arn
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    },
    {
      name  = "region"
      value = var.aws_region
    }
  ]
}

# ─── Cluster Autoscaler ──────────────────────────────────────────────────────
resource "helm_release" "cluster_autoscaler" {
  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = var.cluster_autoscaler_chart_version
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 300

  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = var.cluster_name
    },
    {
      name  = "awsRegion"
      value = var.aws_region
    },
    {
      name  = "rbac.serviceAccount.create"
      value = "true"
    },
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = var.cluster_autoscaler_role_arn
    },
    {
      name  = "extraArgs.balance-similar-node-groups"
      value = "true"
    },
    {
      name  = "extraArgs.skip-nodes-with-system-pods"
      value = "false"
    }
  ]
}

# ─── Secrets Store CSI Driver ────────────────────────────────────────────────
resource "helm_release" "secrets_store_csi" {
  name             = "csi-secrets-store"
  repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart            = "secrets-store-csi-driver"
  version          = var.secrets_store_csi_chart_version
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 300

  set = [
    {
      name  = "syncSecret.enabled"
      value = "true"
    },
    {
      name  = "enableSecretRotation"
      value = "true"
    },
    {
      name  = "rotationPollInterval"
      value = "3600s"
    }
  ]
}

# ─── AWS Secrets Manager Provider for Secrets Store CSI ─────────────────────
resource "helm_release" "secrets_provider_aws" {
  name             = "secrets-provider-aws"
  repository       = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart            = "secrets-store-csi-driver-provider-aws"
  version          = var.secrets_provider_aws_chart_version
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 300

  depends_on = [helm_release.secrets_store_csi]
}

# ─── Metrics Server ──────────────────────────────────────────────────────────
# Required by Horizontal Pod Autoscaler (HPA) and `kubectl top`
resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server"
  chart            = "metrics-server"
  version          = var.metrics_server_chart_version
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 300
}
