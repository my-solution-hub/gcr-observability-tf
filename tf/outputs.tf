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

output "hello_instance_ids" {
  description = "IDs of the Hello (Java Spring Boot) instances"
  value       = aws_instance.hello[*].id
}

output "world_instance_ids" {
  description = "IDs of the World (Python Flask) instances"
  value       = aws_instance.world[*].id
}

output "hello_private_ips" {
  description = "Private IP addresses of the Hello instances"
  value       = aws_instance.hello[*].private_ip
}

output "world_private_ips" {
  description = "Private IP addresses of the World instances"
  value       = aws_instance.world[*].private_ip
}

output "hello_alb_dns_name" {
  description = "DNS name of the Hello Application Load Balancer"
  value       = aws_lb.main[0].dns_name
}

output "world_alb_dns_name" {
  description = "DNS name of the World Application Load Balancer"
  value       = aws_lb.main[1].dns_name
}

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
