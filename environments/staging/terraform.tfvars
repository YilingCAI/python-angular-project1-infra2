environment  = "staging"
project_name = "mypythonproject1-staging"
aws_region   = "us-east-1"

# Kubeconfig — run: aws eks update-kubeconfig --name mypythonproject1-staging-eks --region us-east-1
kubeconfig_path    = "~/.kube/config"
kubeconfig_context = "arn:aws:eks:us-east-1:769254791061:cluster/mypythonproject1-staging-eks"

# Networking
vpc_cidr              = "10.1.0.0/16"
availability_zones    = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs  = ["10.1.10.0/24", "10.1.11.0/24"]
database_subnet_cidrs = ["10.1.20.0/24", "10.1.21.0/24"]
app_port              = 8000
frontend_port         = 4200

# RDS
db_name                  = "gamedb"
db_username              = "postgres"
db_engine_version        = "17.6"
db_instance_class        = "db.t3.small"
db_allocated_storage     = 50
db_max_allocated_storage = 200
backup_retention_days    = 15
multi_az                 = true
log_retention_days       = 7

# EKS
kubernetes_version     = "1.32"
endpoint_public_access = true
node_instance_types    = ["t3.large"]
node_capacity_type     = "ON_DEMAND"
node_disk_size         = 20
desired_node_count     = 2
min_node_count         = 2
max_node_count         = 5
app_namespace          = "app"
app_service_account    = "app-sa"

# ALB & Security
health_check_path = "/health"
certificate_arn   = "" # Add your ACM certificate ARN here

# Helm System Add-ons (override chart versions if needed)
# alb_controller_chart_version      = "1.10.0"
# cluster_autoscaler_chart_version  = "9.46.0"

# ArgoCD
argocd_chart_version      = "7.8.3"
argocd_hostname           = "argocd.staging.example.com" # Replace with your domain
argocd_ingress_enabled    = true
argocd_server_replicas    = 1
argocd_create_app_project = false # Enable after first apply

# App-of-apps bootstrap (set after ArgoCD is running)
argocd_app_repo_url = "" # e.g. https://github.com/org/mypythonproject1
argocd_app_revision = "staging"
argocd_app_path     = "k8s/overlay/staging"

# JWT (provide during terraform apply)
# jwt_secret_key = "your-secret-key-here"
