variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "project_name" {
  type    = string
  default = "aws-platform-reference"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "enable_vpc" {
  type        = bool
  description = "Create the VPC (optional). Disable to keep AWS spend near-zero."
  default     = false
}

variable "vpc_cidr" {
  type        = string
  default     = "10.42.0.0/16"
}

variable "azs" {
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnets" {
  type        = list(string)
  default     = ["10.42.0.0/24", "10.42.1.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  default     = ["10.42.10.0/24", "10.42.11.0/24"]
}

variable "budget_email" {
  type        = string
  description = "Email for AWS Budget alerts."
  default     = ""
}

