module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = [var.private_subnets[0], var.private_subnets[1], var.private_subnets[2]]
  control_plane_subnet_ids = [var.private_subnets[0], var.private_subnets[1], var.private_subnets[2]]

  eks_managed_node_group_defaults = {
    instance_types = ["m6a.large"]
  }

  eks_managed_node_groups = {
    infra = {
      desired_capacity = 2
      min_size         = 1
      max_size         = 10

      instance_types = ["t3a.large"]
      capacity_type  = "ON_DEMAND"
    }
  }

  manage_aws_auth_configmap = true

  tags = {
    Environment = "${var.environment}"
    Terraform   = "true"
  }
}
