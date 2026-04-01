terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40.0, < 6.0"
    }
  }



terraform {
  backend "s3" {
    bucket         = "botp-terraform-states-rahul-2026"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source      = "../../modules/vpc"
  cidr_block  = var.cidr_block
  environment = var.environment
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.1"

  cluster_name    = "${var.environment}-eks"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
    }
  }
}

