module "eks" {
  source = "terraform-aws-modules/eks/aws"

  name               = var.cluster_name
  kubernetes_version = "1.32"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_public_access = true

  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  # Enable recommended security group rules
  node_security_group_enable_recommended_rules = true

  # Access entries for admin roles and users
  access_entries = merge(
    # Original access role
    var.access_role_arn != "" ? {
      admin_role = {
        principal_arn = var.access_role_arn
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {},
    
    # Additional admin role
    var.eks_admin_role_arn != "" ? {
      additional_admin_role = {
        principal_arn = var.eks_admin_role_arn
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {},
    
    # Admin user
    var.eks_admin_user_arn != "" ? {
      admin_user = {
        principal_arn = var.eks_admin_user_arn
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    } : {}
  )

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
    amazon-cloudwatch-observability = {
      most_recent                 = true
      service_account_role_arn    = aws_iam_role.otel_collector_role.arn
      preserve                    = false
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"

    }
  }

  eks_managed_node_groups = {
    main = {
      instance_types = [var.node_instance_type]
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size

      ami_type = "AL2023_x86_64_STANDARD"
      
      # Ensure VPC CNI is available
      create_before_destroy = true
      
      # Add CloudWatch agent permissions
      iam_role_additional_policies = {
        CloudWatchAgentServerPolicy = "arn:aws-cn:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
    }
  }

  tags = var.tags
}

# OpenTelemetry Collector IAM role for service account
resource "aws_iam_role" "otel_collector_role" {
  name = "${var.cluster_name}-otel-collector"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "otel_collector_policy" {
  name = "${var.cluster_name}-otel-collector"
  role = aws_iam_role.otel_collector_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}
