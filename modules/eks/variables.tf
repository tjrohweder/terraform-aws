variable "vpc_id" {}
variable "cluster_name" {}

variable "private_subnets" {
  type = "list"
}

variable "workers_instance_type" {}
