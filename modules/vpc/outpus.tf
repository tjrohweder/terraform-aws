output "private_subnets" {
  value = aws_subnet.private.*.id
}

output "public_subnets" {
  value = aws_subnet.public.*.id
}

output "nat_ips" {
  value = aws_eip.nat_ips.*.id
}

output "nat_gateway" {
  value = aws_nat_gateway.k8s_nat.*.id
}

output "vpc_id" {
  value = aws_vpc.k8s.id
}
