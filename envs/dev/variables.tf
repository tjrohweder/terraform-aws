variable "region" {
  description = "AWS region"
  type        = string

  validation {
    condition     = var.region == "us-east-1"
    error_message = "Region must be 'us-east-1'"
  }
}

variable "env" {
  validation {
    condition     = var.env == "dev"
    error_message = "${var.env} not allowed as a name for the development environment. Must be dev"
  }
}

variable "common_tags" {
  description = "Base tags applied to all resources"
  type        = map(string)
}

variable "vpc" {
  type = object({
    cidr                            = string
    enable_nat_gateway              = bool
    single_nat_gateway              = bool
    create_database_subnet_group    = bool
    create_elasticache_subnet_group = bool
    create_egress_only_igw          = bool
    create_redshift_subnet_group    = bool
  })

  validation {
    condition     = can(cidrhost(var.vpc.cidr, 0))
    error_message = "The VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "eks" {
  type = object({
    version                                  = string
    upgrade_policy                           = string
    instance_type                            = string
    ami                                      = string
    endpoint_public_access                   = bool
    enable_cluster_creator_admin_permissions = bool
  })
}
