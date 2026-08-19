# Terraform + provider pins, and the remote state backend.
#
# State lives in a small S3 bucket so the pipeline stays consistent across runs
# and machines. S3 native locking (use_lockfile) means no DynamoDB table is
# needed. The bucket is bootstrapped once, outside Terraform, so the backend has
# somewhere to write on the very first init.
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "dream-vacation-tfstate-528757827493"
    key          = "stage7/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
