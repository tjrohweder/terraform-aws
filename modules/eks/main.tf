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

  #  create_aws_auth_configmap = true
  #  manage_aws_auth_configmap = true

  tags = {
    Environment              = "${var.environment}"
    Terraform                = "true"
    "karpenter.sh/discovery" = "main"
  }
}

/*module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  tags = {
    Terraform = "true"
  }
}
*/

module "karpenter_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 3.0"

  name        = "karpenter-policy-infra"
  path        = "/"
  description = "karpenter_policy-infra"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "MergedAllowAllActions",
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeInstanceTypeOfferings",
                "ec2:DescribeAvailabilityZones",
                "ec2:CreateTags",
                "ec2:CreateLaunchTemplate",
                "ec2:CreateFleet",
                "ec2:DescribeImages",
                "ec2:DescribeSpotPriceHistory",
                "pricing:GetProducts",
                "ssm:GetParameter",
                "iam:PassRole",
                "eks:DescribeCluster"
            ]
        },
        {
            "Sid": "ConditionalEC2TerminationMain",
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "ec2:TerminateInstances",
                "ec2:DeleteLaunchTemplate"
            ],
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/karpenter.sh/discovery": "main"
                }
            }
        },
        {
            "Sid": "ConditionalEC2TerminationKarpenter",
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "ec2:TerminateInstances"
            ],
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/Name": "*karpenter*"
                }
            }
        },
        {
            "Sid": "ConditionalRunInstancesMain",
            "Effect": "Allow",
            "Resource": [
                "arn:aws:ec2:*:872675253839:subnet/*",
                "arn:aws:ec2:*:872675253839:security-group/*",
                "arn:aws:ec2:*:872675253839:launch-template/*"
            ],
            "Action": [
                "ec2:RunInstances"
            ],
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/karpenter.sh/discovery": "main"
                }
            }
        },
        {
            "Sid": "UnconditionalRunInstances",
            "Effect": "Allow",
            "Resource": [
                "arn:aws:ec2:*::image/*",
                "arn:aws:ec2:*:872675253839:volume/*",
                "arn:aws:ec2:*:872675253839:network-interface/*",
                "arn:aws:ec2:*:872675253839:instance/*"
            ],
            "Action": [
                "ec2:RunInstances"
            ]
        }
    ]
}
EOF
}


module "iam_eks_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "KarpenterControllerRole"

  role_policy_arns = {
    policy = "${module.karpenter_policy.arn}"
  }

  oidc_providers = {
    one = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}

resource "aws_iam_role" "karpenter" {
  name = "KarpenterNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    App = "Karpenter"
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.karpenter.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.karpenter.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.karpenter.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.karpenter.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "karpenterNodeInstanceProfile"
  role = aws_iam_role.karpenter.name
}

