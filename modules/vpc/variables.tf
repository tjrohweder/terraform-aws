variable "vpc_cidr" {}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "nat_ips" {
  type = list(string)
}

variable "nat_gateway" {
  type = list(string)
}
