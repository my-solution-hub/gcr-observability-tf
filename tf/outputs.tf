output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

# EKS Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "otel_collector_role_arn" {
  description = "OpenTelemetry Collector IAM role ARN for service account"
  value       = module.eks.otel_collector_role_arn
}

# Database Outputs
output "rds_cluster_endpoint" {
  description = "RDS cluster writer endpoint"
  value       = aws_rds_cluster.main.endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "RDS cluster reader endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

# ECR Repository Outputs
output "hello_service_ecr_repository_url" {
  description = "ECR repository URL for hello service"
  value       = aws_ecr_repository.hello_service.repository_url
}

output "world_service_ecr_repository_url" {
  description = "ECR repository URL for world service"
  value       = aws_ecr_repository.world_service.repository_url
}

output "traffic_generator_ecr_repository_url" {
  description = "ECR repository URL for traffic generator"
  value       = aws_ecr_repository.traffic_generator.repository_url
}
