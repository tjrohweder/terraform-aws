variable "vpc_id" {}
variable "cluster_name" {}

variable "private_subnets" {
  type = list(string)
}

variable "workers_instance_type" {}

variable "eks_addons" {
  type = list(string)
}