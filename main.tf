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

data "aws_caller_identity" "current" {}

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
  eks_addons            = var.eks_addons
}

module "managed-service-prometheus" {
  source          = "terraform-aws-modules/managed-service-prometheus/aws"
  version         = "2.2.2"
  workspace_alias = "amp"
}

resource "aws_iam_policy" "amp" {
  name = "PrometheusWritePermission"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "aps:RemoteWrite",
        ]
        Effect   = "Allow"
        Resource = "${module.managed-service-prometheus.workspace_arn}"
      },
    ]
  })
}

resource "aws_iam_role" "amp" {
  name = "PrometheusWritePermission"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.id}:oidc-provider/${trimprefix(module.eks.oidc_issuer, "https://")}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${trimprefix(module.eks.oidc_issuer, "https://")}:aud" : "sts.amazonaws.com",
            "${trimprefix(module.eks.oidc_issuer, "https://")}:sub" : "system:serviceaccount:prometheus:amp-iamproxy-ingest"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role" "grafana" {
  name = "GrafanaReadPermission"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::${var.platform_account_id}:role/GrafanaReadPermission"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "amp" {
  name       = "PrometheusWritePermission"
  roles      = [aws_iam_role.amp.name]
  policy_arn = aws_iam_policy.amp.arn
}

resource "aws_iam_policy" "grafana" {
  name = "GrafanaReadPermission"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "aps:GetLabels",
          "aps:GetMetricMetadata",
          "aps:GetSeries",
          "aps:QueryMetrics"
        ]
        Effect   = "Allow"
        Resource = "${module.managed-service-prometheus.workspace_arn}"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "grafana" {
  name       = "GrafanaReadPermission"
  roles      = [aws_iam_role.grafana.name]
  policy_arn = aws_iam_policy.grafana.arn
}
