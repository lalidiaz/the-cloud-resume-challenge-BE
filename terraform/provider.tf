terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    bucket  = "tf-state-bucket-laura"
    key     = "state-be/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

}

provider "aws" {
  region = var.aws_region
}
