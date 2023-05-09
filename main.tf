terraform {
  required_version = ">= 0.14.1"
  required_providers {
    aws = ">= 3.37"
  }

  backend "remote" {
    organization = "tjrohweder"

    workspaces {
      name = "Development"
    }
  }
}

locals {
  environment = "dev"
}

data "aws_caller_identity" "current" {}

provider "aws" {}

module "vpc" {
  source          = "./modules/vpc"
  vpc_cidr        = var.vpc_cidr
  vpc_name        = var.vpc_name
  az_names        = var.az_names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  environment     = local.environment
}

module "eks" {
  source          = "./modules/eks"
  vpc_id          = module.vpc.vpc_id
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  private_subnets = module.vpc.private_subnets
  environment     = local.environment
}
