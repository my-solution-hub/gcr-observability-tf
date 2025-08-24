terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  # AWS China regions require different endpoints
  dynamic "endpoints" {
    for_each = startswith(var.aws_region, "cn-") ? [1] : []
    content {
      ec2         = "https://ec2.${var.aws_region}.amazonaws.com.cn"
      iam         = "https://iam.cn-north-1.amazonaws.com.cn"
      rds         = "https://rds.${var.aws_region}.amazonaws.com.cn"
      s3          = "https://s3.${var.aws_region}.amazonaws.com.cn"
      sts         = "https://sts.${var.aws_region}.amazonaws.com.cn"
      eks         = "https://eks.${var.aws_region}.amazonaws.com.cn"
      elasticache = "https://elasticache.${var.aws_region}.amazonaws.com.cn"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
    }
  }
}

# Data sources to resolve IAM ARNs from names
data "aws_iam_role" "eks_admin_role" {
  count = var.eks_admin_role_name != "" ? 1 : 0
  name  = var.eks_admin_role_name
}

data "aws_iam_user" "eks_admin_user" {
  count     = var.eks_admin_user_name != "" ? 1 : 0
  user_name = var.eks_admin_user_name
}

# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-${var.environment}-${var.aws_region}"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Environment = var.environment
    Region      = var.aws_region
    Project     = var.project_name
  }
}

# EKS cluster
module "eks" {
  source = "./modules/eks"

  cluster_name = "${var.environment}-${var.aws_region}"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets

  node_instance_type = var.eks_node_instance_type
  node_min_size      = var.eks_node_min_size
  node_max_size      = var.eks_node_max_size
  node_desired_size  = var.eks_node_desired_size

  access_role_arn      = var.eks_access_role_arn
  eks_admin_role_arn   = var.eks_admin_role_name != "" ? data.aws_iam_role.eks_admin_role[0].arn : ""
  eks_admin_user_arn   = var.eks_admin_user_name != "" ? data.aws_iam_user.eks_admin_user[0].arn : ""

  tags = {
    Environment = var.environment
    Region      = var.aws_region
    Project     = var.project_name
  }
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id, module.eks.node_security_group_id]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security group for Redis
resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-${var.environment}-redis"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id, module.eks.node_security_group_id]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDS Aurora MySQL Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.project_name}-${var.environment}-${var.aws_region}"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.09.0"
  database_name           = "observability"
  master_username         = "admin"
  master_password         = "changeme123!"
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  skip_final_snapshot = true

  tags = {
    Environment = var.environment
    Region      = var.aws_region
    Project     = var.project_name
  }
}

resource "aws_rds_cluster_instance" "main" {
  count              = 2
  identifier         = "${var.project_name}-${var.environment}-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.rds_instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-${var.aws_region}"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-${var.aws_region}"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.project_name}-${var.environment}-redis"
  description                = "Redis cluster for observability demo"
  
  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  tags = {
    Environment = var.environment
    Region      = var.aws_region
    Project     = var.project_name
  }
}

# ECR Repositories
resource "aws_ecr_repository" "hello_service" {
  name                 = "${var.project_name}-hello-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = "hello"
  }
}

resource "aws_ecr_repository" "world_service" {
  name                 = "${var.project_name}-world-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Service     = "world"
  }
}
