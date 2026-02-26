locals {
  state_bucket_name = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"
  lock_table_name   = "${var.project_name}-tflock"
  gha_role_name     = "${var.project_name}-gha-terraform"

  tags = {
    Project     = var.project_name
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
  }
}

data "aws_caller_identity" "current" {}

# -------------------------
# Terraform state bucket
# -------------------------
resource "aws_s3_bucket" "tf_state" {
  bucket        = local.state_bucket_name
  force_destroy = false
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce bucket owner controls (recommended baseline)
resource "aws_s3_bucket_ownership_controls" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Cost control: expire old noncurrent versions (state bucket has versioning enabled)
resource "aws_s3_bucket_lifecycle_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 60
    }
  }
}

# Enforce TLS-only access to the state bucket
data "aws_iam_policy_document" "tf_state_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.tf_state.arn,
      "${aws_s3_bucket.tf_state.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  policy = data.aws_iam_policy_document.tf_state_tls_only.json
}

# -------------------------
# Optional: legacy DynamoDB lock table
# Not required when using `use_lockfile = true` in the S3 backend.
# -------------------------
resource "aws_dynamodb_table" "tf_lock" {
  count        = var.enable_dynamodb_lock ? 1 : 0
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  tags         = local.tags

  attribute {
    name = "LockID"
    type = "S"
  }
}

# -------------------------
# Optional: GitHub Actions OIDC + role
# -------------------------
resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_oidc ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # GitHub Actions OIDC root CA thumbprint (commonly used).
  # Note: if this ever changes, update the thumbprint per GitHub/AWS guidance.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = local.tags
}

data "aws_iam_policy_document" "gha_assume_role" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Lock to a single repo + branch
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "gha_terraform" {
  count              = var.enable_github_oidc ? 1 : 0
  name               = local.gha_role_name
  assume_role_policy = data.aws_iam_policy_document.gha_assume_role[0].json
  tags               = local.tags
}

# Minimal policy for Terraform backend operations (state bucket + optional DynamoDB lock)
data "aws_iam_policy_document" "gha_terraform_minimal" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    sid     = "TerraformStateBucketList"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      aws_s3_bucket.tf_state.arn
    ]
  }

  statement {
    sid    = "TerraformStateBucketObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.tf_state.arn}/*"
    ]
  }

  dynamic "statement" {
    for_each = var.enable_dynamodb_lock ? [1] : []
    content {
      sid    = "TerraformStateLockTable"
      effect = "Allow"
      actions = [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:UpdateItem"
      ]
      resources = [aws_dynamodb_table.tf_lock[0].arn]
    }
  }
}

resource "aws_iam_policy" "gha_terraform_minimal" {
  count  = var.enable_github_oidc ? 1 : 0
  name   = "${var.project_name}-gha-terraform-minimal"
  policy = data.aws_iam_policy_document.gha_terraform_minimal[0].json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "gha_terraform_minimal" {
  count      = var.enable_github_oidc ? 1 : 0
  role       = aws_iam_role.gha_terraform[0].name
  policy_arn = aws_iam_policy.gha_terraform_minimal[0].arn
}

# -------------------------
# Outputs
# -------------------------
output "tf_state_bucket" {
  value       = aws_s3_bucket.tf_state.bucket
  description = "S3 bucket used for Terraform state."
}

output "tf_lock_table" {
  value       = var.enable_dynamodb_lock ? aws_dynamodb_table.tf_lock[0].name : null
  description = "DynamoDB lock table name (null if disabled)."
}

output "gha_role_arn" {
  value       = var.enable_github_oidc ? aws_iam_role.gha_terraform[0].arn : null
  description = "GitHub Actions role ARN (null if disabled)."
}

output "aws_region" {
  value       = var.aws_region
  description = "AWS region for bootstrap."
}