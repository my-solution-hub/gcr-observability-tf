variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "observability-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t4g.micro"
}

# EKS Configuration
variable "eks_node_instance_type" {
  description = "EKS node instance type"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_min_size" {
  description = "EKS node group minimum size"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "EKS node group maximum size"
  type        = number
  default     = 5
}

variable "eks_node_desired_size" {
  description = "EKS node group desired size"
  type        = number
  default     = 3
}

variable "eks_access_role_arn" {
  description = "IAM role ARN to grant full EKS access (optional)"
  type        = string
  default     = ""
}

variable "eks_admin_role_name" {
  description = "IAM role name to grant EKS admin access (optional)"
  type        = string
  default     = ""
}

variable "eks_admin_user_name" {
  description = "IAM user name to grant EKS admin access (optional)"
  type        = string
  default     = ""
}
