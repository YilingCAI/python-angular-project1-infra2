environment  = "prod"
project_name = "mypythonproject1-prod"
aws_region   = "us-east-1"

# Kubeconfig — run: aws eks update-kubeconfig --name mypythonproject1-prod-eks --region us-east-1
kubeconfig_path    = "~/.kube/config"
<<<<<<< HEAD
kubeconfig_context = "arn:aws:eks:us-east-1:388252587928:cluster/mypythonproject1-prod-eks"
=======
kubeconfig_context = "arn:aws:eks:us-east-1:769254791061:cluster/mypythonproject1-prod-eks"
>>>>>>> feature/init

# Networking
vpc_cidr              = "10.2.0.0/16"
availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs   = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs  = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
database_subnet_cidrs = ["10.2.20.0/24", "10.2.21.0/24", "10.2.22.0/24"]
app_port              = 8000
frontend_port         = 4200

# RDS
db_name                  = "gamedb"
db_username              = "postgres"
db_engine_version        = "17.6"
db_instance_class        = "db.t3.medium"
db_allocated_storage     = 100
db_max_allocated_storage = 500
backup_retention_days    = 30
multi_az                 = true
log_retention_days       = 30

# EKS
kubernetes_version     = "1.32"
endpoint_public_access = false # Private endpoint in production
node_instance_types    = ["t3.xlarge"]
node_capacity_type     = "ON_DEMAND"
node_disk_size         = 50
desired_node_count     = 3
min_node_count         = 3
max_node_count         = 10
app_namespace          = "app"
app_service_account    = "app-sa"

# ALB & Security
health_check_path = "/health"
certificate_arn   = "" # REQUIRED: Add your ACM certificate ARN here for production

# Helm System Add-ons (override chart versions if needed)
# alb_controller_chart_version      = "1.10.0"
# cluster_autoscaler_chart_version  = "9.46.0"

# ArgoCD — HA configuration for production
argocd_chart_version      = "7.8.3"
argocd_hostname           = "argocd.prod.example.com" # Replace with your domain
argocd_ingress_enabled    = true
argocd_server_replicas    = 2     # HA: 2 replicas in prod
argocd_create_app_project = false # Enable after first apply

# App-of-apps bootstrap (set after ArgoCD is running)
argocd_app_repo_url = "" # e.g. https://github.com/org/mypythonproject1
argocd_app_revision = "main"
argocd_app_path     = "k8s/overlay/prod"

# JWT (provide during terraform apply)
# jwt_secret_key = "your-secret-key-here"
