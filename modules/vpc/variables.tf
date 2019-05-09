variable "vpc_cidr" {}

variable "private_subnets" {
  type = "list"
}

variable "public_subnets" {
  type = "list"
}

variable "nat_ips" {
  type = "list"
}

variable "nat_gateway" {
  type = "list"
}
