terraform {
  backend "s3" {
    bucket       = "aws-platform-reference-tfstate-231348293931"
    key          = "envs/dev/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

