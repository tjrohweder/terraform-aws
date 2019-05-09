data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.prod_cluster.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"]
}

resource "aws_iam_role" "prod_cluster" {
  name = "prod-eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "prod_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.prod_cluster.name}"
}

resource "aws_iam_role_policy_attachment" "prod_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.prod_cluster.name}"
}

resource "aws_security_group" "prod_cluster" {
  name   = "prod_cluster_sg"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EKS Prod Security Group"
  }
}

resource "aws_security_group_rule" "prod_cluster_ingress-workstation-https" {
  cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.prod_cluster.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group" "prod-node" {
  name   = "prod-node-sg"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "Worker Nodes Security Group",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

resource "aws_eks_cluster" "prod_cluster" {
  name     = "${var.cluster_name}"
  role_arn = "${aws_iam_role.prod_cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.prod_cluster.id}"]
    subnet_ids         = ["${var.private_subnets}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.prod_cluster_AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.prod_cluster_AmazonEKSServicePolicy",
  ]
}

resource "aws_iam_role" "prod-node" {
  name = "eks-prod-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-prod-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.prod-node.name}"
}

resource "aws_iam_role_policy_attachment" "prod-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.prod-node.name}"
}

resource "aws_iam_role_policy_attachment" "prod-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.prod-node.name}"
}

resource "aws_iam_instance_profile" "prod-node" {
  name = "prod-node"
  role = "${aws_iam_role.prod-node.name}"
}

locals {
  prod_node_userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.prod_cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.prod_cluster.certificate_authority.0.data}' '${var.cluster_name}'
USERDATA
}

resource "aws_launch_configuration" "eks_launch_config" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.prod-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m5.large"
  name_prefix                 = "eks-node"
  security_groups             = ["${aws_security_group.prod-node.id}"]
  user_data_base64            = "${base64encode(local.prod_node_userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks_nodes_autoscaling" {
  desired_capacity     = 3
  launch_configuration = "${aws_launch_configuration.eks_launch_config.id}"
  max_size             = 15
  min_size             = 3
  name                 = "eks_nodes"
  vpc_zone_identifier  = ["${var.private_subnets}"]

  tag {
    key                 = "Name"
    value               = "eks-prod-nodes"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.prod-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH
}
