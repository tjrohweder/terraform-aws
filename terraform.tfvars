profile               = "default"
aws_region            = "us-east-1"
vpc_cidr              = "10.0.0.0/16"
cluster_name          = "production"
workers_instance_type = "t3a.medium"
eks_addons            = ["coredns", "kube-proxy", "vpc-cni", "aws-ebs-csi-driver"]
platform_account_id   = "528964206988" 