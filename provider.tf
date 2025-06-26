terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_accessKey
  secret_key = var.aws_secretKey
}