locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# SAFE DEFAULT:
# dev is a no-op unless enable_vpc=true
module "vpc" {
  count        = var.enable_vpc ? 1 : 0
  source       = "../../modules/vpc"
  project_name = var.project_name
  environment  = var.environment

  vpc_cidr        = "10.42.0.0/16"
  azs             = ["us-west-2a", "us-west-2b"]
  public_subnets  = ["10.42.0.0/24", "10.42.1.0/24"]
  private_subnets = ["10.42.10.0/24", "10.42.11.0/24"]

  tags = local.tags
}
