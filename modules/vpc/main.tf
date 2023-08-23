module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = [var.az_names[0], var.az_names[1], var.az_names[2]]
  private_subnets = [var.private_subnets[0], var.private_subnets[1], var.private_subnets[2]]
  public_subnets  = [var.public_subnets[0], var.public_subnets[1], var.public_subnets[2]]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform                = "true"
    Environment              = "${var.environment}"
    "karpenter.sh/discovery" = "main"
  }
}
