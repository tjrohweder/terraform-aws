variable "vpc_id" {}
variable "cluster_name" {}
variable "cluster_version" {}
variable "environment" {}
variable "private_subnets" {
  type = list(string)
}
