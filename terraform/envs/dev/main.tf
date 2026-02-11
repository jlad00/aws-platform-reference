locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --------------------------------------------
# SAFE DEFAULTS:
# - No EKS in dev (local-k8s is the platform layer)
# - VPC is optional because NAT gateways cost money if enabled
# --------------------------------------------

module "vpc" {
  count        = var.enable_vpc ? 1 : 0
  source       = "../../modules/vpc"
  project_name = var.project_name
  environment  = var.environment

  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  tags = local.tags
}

module "budget" {
  source       = "../../modules/budget"
  project_name = var.project_name
  environment  = var.environment
  email        = var.budget_email
}
