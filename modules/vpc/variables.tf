variable "az_names" {
  type = list(string)
}
variable "vpc_name" {
  type = string
}
variable "private_subnets" {
  type = list(string)
}
variable "public_subnets" {
  type = list(string)
}
variable "environment" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
