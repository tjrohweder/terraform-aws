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

module "vpc" {
  source          = "./modules/vpc"
  vpc_cidr        = var.vpc_cidr
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  nat_ips         = module.vpc.nat_ips
  nat_gateway     = module.vpc.nat_gateway
}

module "eks" {
  source                = "./modules/eks"
  vpc_id                = module.vpc.vpc_id
  cluster_name          = var.cluster_name
  private_subnets       = module.vpc.private_subnets
  workers_instance_type = var.workers_instance_type
}
