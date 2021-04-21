variable "vpc_id" {}
variable "cluster_name" {}

variable "private_subnets" {
  type = list(string)
}

variable "workers_instance_type" {}
