data "aws_availability_zones" "available" {
  state = "available"
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = var.env
  cidr = var.vpc.cidr
  azs  = data.aws_availability_zones.available.names

  private_subnets = [
    cidrsubnet(var.vpc.cidr, 4, 0),
    cidrsubnet(var.vpc.cidr, 4, 1),
    cidrsubnet(var.vpc.cidr, 4, 2),
  ]

  public_subnets = [
    cidrsubnet(var.vpc.cidr, 8, 50),
    cidrsubnet(var.vpc.cidr, 8, 51),
    cidrsubnet(var.vpc.cidr, 8, 52),
  ]

  enable_nat_gateway              = var.vpc.enable_nat_gateway
  single_nat_gateway              = var.vpc.single_nat_gateway
  create_database_subnet_group    = var.vpc.create_database_subnet_group
  create_elasticache_subnet_group = var.vpc.create_elasticache_subnet_group
  create_egress_only_igw          = var.vpc.create_egress_only_igw
  create_redshift_subnet_group    = var.vpc.create_redshift_subnet_group

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name                             = var.env
  cluster_version                          = var.eks.version
  cluster_endpoint_public_access           = var.eks.endpoint_public_access
  enable_cluster_creator_admin_permissions = var.eks.enable_cluster_creator_admin_permissions

  cluster_upgrade_policy = {
    support_type = var.eks.upgrade_policy
  }

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }
  }

  eks_managed_node_groups = {
    main = {
      ami_type       = var.eks.ami
      instance_types = [var.eks.instance_type]

      min_size     = 1
      max_size     = 10
      desired_size = 2
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = local.tags
}
