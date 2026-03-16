provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Kubernetes provider — reads from a local kubeconfig file.
# Generate / refresh it with:
#   aws eks update-kubeconfig --name <cluster-name> --region <region>
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

# Helm provider — same kubeconfig as the Kubernetes provider above.
provider "helm" {
  kubernetes = {
    config_path    = var.kubeconfig_path
    config_context = var.kubeconfig_context
  }
}
