/**
 * VPC and Networking Resources for EKS
 * - VPC with configurable CIDR
 * - Public subnets: ALB + NAT (tagged for EKS external ALB)
 * - Private subnets: EKS nodes (tagged for EKS internal ALB)
 * - Database subnets: RDS
 * - NAT Gateway, IGW, route tables
 * - VPC Flow Logs
 */

data "aws_caller_identity" "current" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                        = "${var.project_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Restrict default security group (CKV2_AWS_12)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-default-sg" }
}

# VPC Flow Logs (CKV2_AWS_11)
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.project_name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.flow_logs.arn

  tags = { Name = "${var.project_name}-vpc-flow-logs" }
}

resource "aws_kms_key" "flow_logs" {
  description             = "KMS key for VPC Flow Logs"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = { Name = "${var.project_name}-flow-logs-key" }
}

resource "aws_kms_key_policy" "flow_logs" {
  key_id = aws_kms_key.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsUse"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup", "logs:CreateLogStream",
        "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"
      ]
      Effect = "Allow"
      Resource = [
        aws_cloudwatch_log_group.flow_logs.arn,
        "${aws_cloudwatch_log_group.flow_logs.arn}:*"
      ]
    }]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = { Name = "${var.project_name}-vpc-flow-logs" }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-igw" }
}

# Elastic IPs for NAT Gateways (one per AZ for HA)
resource "aws_eip" "nat" {
  count      = var.single_nat_gateway ? 1 : length(var.availability_zones)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = { Name = "${var.project_name}-nat-eip-${count.index + 1}" }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = var.single_nat_gateway ? 1 : length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]

  tags = { Name = "${var.project_name}-nat-${count.index + 1}" }
}

# Public Subnets — tagged for AWS Load Balancer Controller (external ALBs)
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "${var.project_name}-public-subnet-${count.index + 1}"
    Type                                        = "Public"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

# Private Subnets — EKS nodes run here; tagged for internal ALBs
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                        = "${var.project_name}-private-subnet-${count.index + 1}"
    Type                                        = "Private"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# Database Subnets — RDS only, no EKS tags needed
resource "aws_subnet" "database" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-database-subnet-${count.index + 1}"
    Type = "Database"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
  }

  tags = { Name = "${var.project_name}-private-rt-${count.index + 1}" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

# ─── Security Groups ────────────────────────────────────────────────────────

# ALB Security Group
#checkov:skip=CKV2_AWS_5:Security group is attached by consuming modules (ALB resource).
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound to private workloads"
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# EKS Node Security Group — allows ALB → nodes and node → node
#checkov:skip=CKV2_AWS_5:Security group is attached by consuming modules (EKS cluster/node groups).
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes-sg"
  description = "EKS node security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow ALB to reach node ports"
    from_port       = 1024
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "HTTPS egress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS UDP egress"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS TCP egress"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                        = "${var.project_name}-eks-nodes-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Standalone rule to break the cycle: eks_nodes → rds on 5432
resource "aws_security_group_rule" "eks_nodes_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.rds.id
  description              = "PostgreSQL to RDS"
}

# RDS Security Group
#checkov:skip=CKV2_AWS_5:Security group is attached by consuming modules (RDS instance).
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS security group - allows PostgreSQL from EKS nodes"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "RDS outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-rds-sg" }
}

# Standalone rules to break the cycle between eks_nodes ↔ rds
resource "aws_security_group_rule" "rds_from_eks_nodes" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "PostgreSQL from EKS nodes"
}
