az_names        = ["us-east-1a", "us-east-1b", "us-east-1c"]
vpc_name        = "main"
vpc_cidr        = "172.32.0.0/16"
public_subnets  = ["172.32.1.0/24", "172.32.3.0/24", "172.32.5.0/24"]
private_subnets = ["172.32.0.0/24", "172.32.2.0/24", "172.32.4.0/24"]
cluster_name    = "main"
cluster_version = "1.28"
