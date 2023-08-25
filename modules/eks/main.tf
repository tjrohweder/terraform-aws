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

  aws_auth_roles = [
    {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
  ]

  tags = {
    Environment              = "${var.environment}"
    Terraform                = "true"
    "karpenter.sh/discovery" = "main"
  }
}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  tags = {
    Terraform = "true"
  }
}

/*module "karpenter_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 3.0"

  name        = "karpenter-policy-infra"
  path        = "/"
  description = "karpenter_policy-infra"

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "ssm:GetParameter",
                "ec2:DescribeImages",
                "ec2:RunInstances",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeInstanceTypeOfferings",
                "ec2:DescribeAvailabilityZones",
                "ec2:DeleteLaunchTemplate",
                "ec2:CreateTags",
                "ec2:CreateLaunchTemplate",
                "ec2:CreateFleet",
                "ec2:DescribeSpotPriceHistory",
                "pricing:GetProducts",
                "sts:AssumeRoleWithWebIdentity"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "Karpenter"
        },
        {
            "Action": "ec2:TerminateInstances",
            "Condition": {
                "StringLike": {
                    "ec2:ResourceTag/Name": "*karpenter*"
                }
            },
            "Effect": "Allow",
            "Resource": "*",
            "Sid": "ConditionalEC2Termination"
        },
        {
            "Effect": "Allow",
            "Action": "eks:DescribeCluster",
            "Resource": "*",
            "Sid": "EKSClusterEndpointLookup"
        }        
    ],
    "Version": "2012-10-17"
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
      provider_arn               = "arn:aws:iam::872675253839:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/00D1DC25D3F21846E344589BA18A9ED1"
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
*/
