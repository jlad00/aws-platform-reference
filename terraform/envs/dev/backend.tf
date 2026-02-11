terraform {
  backend "s3" {
    bucket         = "aws-platform-reference-tfstate-231348293931"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "aws-platform-reference-tflock"
    encrypt        = true
  }
}
