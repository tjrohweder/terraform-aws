data "aws_availability_zones" "available" {}

resource "aws_vpc" "k8s" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "k8s"
  }
}

resource "aws_subnet" "private" {
  count             = 4
  vpc_id            = aws_vpc.k8s.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 1)

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "public" {
  count                   = 4
  vpc_id                  = aws_vpc.k8s.id
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  cidr_block              = cidrsubnet(var.vpc_cidr, 12, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "k8s_itg" {
  vpc_id = aws_vpc.k8s.id

  tags = {
    Name = "k8s_itg"
  }
}

resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.k8s.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_itg.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = var.public_subnets[count.index]
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_eip" "nat_ips" {
  count = length(var.public_subnets)
  vpc   = true

  tags = {
    Name = "NAT-IP-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "k8s_nat" {
  count         = length(var.private_subnets)
  allocation_id = var.nat_ips[count.index]
  subnet_id     = var.public_subnets[count.index]
}

resource "aws_route_table" "private_routes" {
  count = length(var.private_subnets)
  vpc_id     = aws_vpc.k8s.id
  depends_on = [aws_nat_gateway.k8s_nat]

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway[count.index]
  }

  tags = {
    Name = "Private"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = var.private_subnets[count.index]
  route_table_id = aws_route_table.private_routes[count.index].id
}
