terraform {
  backend "s3" {
    bucket       = "REPLACE_ME"
    key          = "envs/dev/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

