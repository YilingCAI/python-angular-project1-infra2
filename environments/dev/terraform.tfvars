environment  = "dev"
project_name = "mypythonproject1-dev"
aws_region   = "us-east-1"

# Networking
vpc_cidr              = "10.0.0.0/16"
availability_zones    = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]
app_port              = 8000
frontend_port         = 4200

# RDS
db_name                  = "gamedb"
db_username              = "postgres"
db_engine_version        = "17.6"
db_instance_class        = "db.t3.micro"
db_allocated_storage     = 20
db_max_allocated_storage = 100
backup_retention_days    = 7
multi_az                 = true
log_retention_days       = 3

# EKS
kubernetes_version     = "1.32"
endpoint_public_access = true
node_instance_types    = ["t3.medium"]
node_capacity_type     = "SPOT"
node_disk_size         = 20
desired_node_count     = 1
min_node_count         = 1
max_node_count         = 3
app_namespace          = "app"
app_service_account    = "app-sa"

# ALB & Security
health_check_path = "/health"
certificate_arn   = ""

# Helm System Add-ons (override chart versions if needed)
# alb_controller_chart_version      = "1.10.0"
# cluster_autoscaler_chart_version  = "9.46.0"

# ArgoCD
argocd_chart_version      = "7.8.3"
# nip.io — no domain required (HTTP only).
# Step 1: Apply with this placeholder — the ALB will be created.
# Step 2: Get the ALB IP:  dig +short $(kubectl get ingress -n argocd -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}') | head -1
# Step 3: Replace <IP> below with the result (e.g. 1.2.3.4) and re-apply:
#           argocd_hostname = "argocd.<IP>.nip.io"
# Step 4: Set GitHub secret ARGOCD_SERVER = argocd.<IP>.nip.io  (no http://)
argocd_hostname           = "argocd.127.0.0.1.nip.io" # REPLACE 127.0.0.1 with real ALB IP
argocd_ingress_enabled    = true
argocd_server_replicas    = 1
argocd_create_app_project = false # Enable after first apply

# App-of-apps bootstrap (set after ArgoCD is running)
argocd_app_repo_url = "" # e.g. https://github.com/org/mypythonproject1
argocd_app_revision = "dev"
argocd_app_path     = "k8s/overlay/dev"

# EKS cluster-admin access for human operators (kubectl)
admin_iam_arns = [
  "arn:aws:iam::209561932650:user/cloud_user",
]
