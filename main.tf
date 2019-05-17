terraform {
  required_version = ">= 0.11.13"

  backend "s3" {
    bucket = "tjrohweder-terraform-state"
    key    = "state"
    region = "us-east-1"
  }
}

provider "aws" {
  version                 = ">= 2.11"
  profile                 = "${var.profile}"
  shared_credentials_file = "~/.aws/credentials"
  region                  = "${var.aws_region}"
}

module "vpc" {
  source          = "./modules/vpc"
  vpc_cidr        = "${var.vpc_cidr}"
  private_subnets = "${module.vpc.private_subnets}"
  public_subnets  = "${module.vpc.public_subnets}"
  nat_ips         = "${module.vpc.nat_ips}"
  nat_gateway     = "${module.vpc.nat_gateway}"
}

module "eks" {
  source          = "./modules/eks"
  vpc_id          = "${module.vpc.vpc_id}"
  cluster_name    = "${var.cluster_name}"
  private_subnets = "${module.vpc.private_subnets}"
}
