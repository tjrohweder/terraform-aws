region = "us-east-1"
env    = "prod"

common_tags = {
  Project   = "Infrastructure"
  ManagedBy = "Terraform"
  Team      = "SRE"
}

vpc = {
  cidr                            = "172.33.0.0/16"
  enable_nat_gateway              = true
  single_nat_gateway              = false
  create_database_subnet_group    = false
  create_elasticache_subnet_group = false
  create_egress_only_igw          = false
  create_redshift_subnet_group    = false
}

eks = {
  version                                  = "1.34"
  upgrade_policy                           = "STANDARD"
  instance_type                            = "m6a.large"
  ami                                      = "AL2023_x86_64_STANDARD"
  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true
}
