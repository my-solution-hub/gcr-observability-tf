terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  # AWS China regions require different endpoints
  dynamic "endpoints" {
    for_each = startswith(var.aws_region, "cn-") ? [1] : []
    content {
      ec2 = "https://ec2.${var.aws_region}.amazonaws.com.cn"
      iam = "https://iam.cn-north-1.amazonaws.com.cn"
      rds = "https://rds.${var.aws_region}.amazonaws.com.cn"
      s3  = "https://s3.${var.aws_region}.amazonaws.com.cn"
      sts = "https://sts.${var.aws_region}.amazonaws.com.cn"
    }
  }
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

# Security Groups
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${var.environment}-web"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-${var.environment}-redis"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# EC2 Instances - 2 Java Spring Boot (hello) and 2 Python Flask (world)
resource "aws_instance" "hello" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = element(module.vpc.private_subnets, count.index % length(module.vpc.private_subnets))
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user_data_hello.sh", {
    instance_name = "${var.project_name}-hello-${count.index + 1}"
    redis_endpoint = aws_elasticache_replication_group.main.primary_endpoint_address
    world_endpoint = "http://${aws_instance.world[0].private_ip}:5000"
  }))

  tags = {
    Name        = "${var.project_name}-hello-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    AppType     = "hello"
  }

  depends_on = [aws_instance.world, aws_elasticache_replication_group.main]
}

resource "aws_instance" "world" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = element(module.vpc.private_subnets, count.index % length(module.vpc.private_subnets))
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user_data_world.sh", {
    instance_name = "${var.project_name}-world-${count.index + 1}"
    db_endpoint = aws_rds_cluster.main.endpoint
    db_name = "observability"
    db_user = "admin"
    db_password = "changeme123!"
  }))

  tags = {
    Name        = "${var.project_name}-world-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    AppType     = "world"
  }

  depends_on = [aws_rds_cluster.main]
}

# Application Load Balancers
resource "aws_lb" "main" {
  count              = 2
  name               = "${var.project_name}-alb-${count.index + 1}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "hello" {
  name     = "${var.project_name}-hello-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "8080"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "world" {
  name     = "${var.project_name}-world-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "5000"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group_attachment" "hello" {
  count            = 2
  target_group_arn = aws_lb_target_group.hello.arn
  target_id        = aws_instance.hello[count.index].id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "world" {
  count            = 2
  target_group_arn = aws_lb_target_group.world.arn
  target_id        = aws_instance.world[count.index].id
  port             = 5000
}

resource "aws_lb_listener" "hello" {
  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hello.arn
  }
}

resource "aws_lb_listener" "world" {
  load_balancer_arn = aws_lb.main[1].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.world.arn
  }
}

# RDS Aurora MySQL Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.project_name}-${var.environment}-${var.aws_region}"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.02.0"
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
