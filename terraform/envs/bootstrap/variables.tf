variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "project_name" {
  type    = string
  default = "aws-platform-reference"
}

variable "github_owner" {
  type = string
}

variable "github_owner" {
  type        = string
  description = "GitHub org/user that owns the repo (only used when enable_github_oidc=true)."
  default     = ""
}

variable "github_repo" {
  type        = string
  description = "GitHub repo name (only used when enable_github_oidc=true)."
  default     = ""
}

variable "enable_dynamodb_lock" {
  type        = bool
  description = "Create DynamoDB state lock table (legacy). Not required with S3 backend use_lockfile."
  default     = false
}

variable "enable_github_oidc" {
  type        = bool
  description = "Create GitHub OIDC provider + IAM role for GitHub Actions."
  default     = false
}

variable "github_branch" {
  type        = string
  description = "Branch allowed to assume the GitHub Actions role."
  default     = "main"
}

# Optional validation: only enforce when OIDC is enabled
locals {
  _github_inputs_ok = (!var.enable_github_oidc) || (var.github_owner != "" && var.github_repo != "")
}
