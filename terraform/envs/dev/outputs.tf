output "region" {
  value       = var.aws_region
  description = "AWS region for this environment."
}

output "vpc_id" {
  value       = var.enable_vpc ? module.vpc[0].vpc_id : null
  description = "VPC ID (null if enable_vpc=false)."
}

output "public_subnet_ids" {
  value       = var.enable_vpc ? module.vpc[0].public_subnets : null
  description = "Public subnet IDs (null if enable_vpc=false)."
}

output "private_subnet_ids" {
  value       = var.enable_vpc ? module.vpc[0].private_subnets : null
  description = "Private subnet IDs (null if enable_vpc=false)."
}
