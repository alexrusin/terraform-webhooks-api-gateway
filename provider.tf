terraform {
  required_version = "~> 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    region = "us-west-2"
    bucket = "alex-terraform-backends"
    key    = "terraform-api-gateway"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Terraform-Managed = "yes"
    }
  }
}
