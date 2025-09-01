variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS cluster"
  type        = list(string)
}

variable "node_instance_type" {
  description = "Instance type for EKS nodes"
  type        = string
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
}

variable "access_role_arn" {
  description = "IAM role ARN to grant full EKS access (optional)"
  type        = string
  default     = ""
}

variable "eks_admin_role_arn" {
  description = "Additional IAM role ARN to grant EKS admin access (optional)"
  type        = string
  default     = ""
}

variable "eks_admin_user_arn" {
  description = "IAM user ARN to grant EKS admin access (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
