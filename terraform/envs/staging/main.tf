terraform {
  backend "s3" {
    bucket         = "botp-terraform-states-rahul-2026"
    key            = "prod/terraform.tfstate"
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
  source       = "../../modules/eks"
  cluster_name = "${var.environment}-eks"
  environment  = var.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
}
