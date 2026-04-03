terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40.0, < 6.0"
    }
  }

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
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0"

  name = "${var.env}-vpc"
  cidr = var.cidr_block

  azs = ["us-east-1a", "us-east-1b"]
  public_subnets = [
    cidrsubnet(var.cidr_block, 4, 0),
    cidrsubnet(var.cidr_block, 4, 1)
  ]

  map_public_ip_on_launch = true

  private_subnets = [
    cidrsubnet(var.cidr_block, 4, 2),
    cidrsubnet(var.cidr_block, 4, 3)
  ]


  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = var.env
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.1"

  cluster_name    = "${var.env}-eks"
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets


  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Enable IRSA
  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      name           = "default"
      desired_size   = 1
      min_size       = 1
      max_size       = 2
      instance_types = ["t3.medium"]

      # Essential configurations for public subnets
      ami_type      = "AL2_x86_64"
      capacity_type = "ON_DEMAND"

      # Disk configuration
      disk_size = 20
      disk_type = "gp3"

      # Explicitly use your working public subnets
      subnet_ids = ["subnet-0add2dc0ad8f7c53f", "subnet-0305d2f98ebe15682"]

      # Network configuration
      remote_access = {}

      # Use default launch template
      create_launch_template = false
      launch_template_name   = ""

      # Force update strategy
      update_config = {
        max_unavailable_percentage = 50
      }

    }
  }
}
# Enhanced security group rules
node_security_group_additional_rules = {
  ingress_self_all = {
    description = "Node to node all ports/protocols"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    type        = "ingress"
    self        = true
  }

  ingress_cluster_all = {
    description                   = "Cluster to node all ports/protocols"
    protocol                      = "-1"
    from_port                     = 0
    to_port                       = 0
    type                          = "ingress"
    source_cluster_security_group = true
  }

  egress_all = {
    description      = "Node all egress"
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    type             = "egress"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
