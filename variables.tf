variable "profile" {}
variable "aws_region" {}
variable "vpc_cidr" {}
variable "cluster_name" {}
variable "workers_instance_type" {}
variable "platform_account_id" {}
variable "eks_addons" {
  type = list(string)
}