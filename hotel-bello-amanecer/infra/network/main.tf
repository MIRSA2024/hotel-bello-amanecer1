locals {
  subnets = {
    public-a      = { cidr = "10.0.1.0/24", az = "us-east-1a", tier = "public" }
    public-b      = { cidr = "10.0.2.0/24", az = "us-east-1b", tier = "public" }
    private-app-a = { cidr = "10.0.11.0/24", az = "us-east-1a", tier = "app" }
    private-app-b = { cidr = "10.0.12.0/24", az = "us-east-1b", tier = "app" }
    private-db-a  = { cidr = "10.0.21.0/24", az = "us-east-1a", tier = "db" }
    private-db-b  = { cidr = "10.0.22.0/24", az = "us-east-1b", tier = "db" }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "hba-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "hba-igw" }
}

resource "aws_subnet" "this" {
  for_each                = local.subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.tier == "public"
  tags                    = { Name = "hba-${each.key}", Tier = each.value.tier }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "hba-nat-eip" }
}

resource "aws_nat_gateway" "nat" { # una sola NAT (ahorro en laboratorio)
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.this["public-a"].id
  tags          = { Name = "hba-nat-a" }
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "hba-rt-public" }
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "hba-rt-private-app" }
}

resource "aws_route_table" "db" { # sin rutas: solo tráfico local
  vpc_id = aws_vpc.main.id
  tags   = { Name = "hba-rt-isolated" }
}

locals {
  rt_by_tier = {
    public = aws_route_table.public.id
    app    = aws_route_table.app.id
    db     = aws_route_table.db.id
  }
}

resource "aws_route_table_association" "this" {
  for_each       = aws_subnet.this
  subnet_id      = each.value.id
  route_table_id = local.rt_by_tier[local.subnets[each.key].tier]
}

resource "aws_vpc_endpoint" "s3" { # tráfico a S3 sin salir por la NAT
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.app.id]
  tags              = { Name = "hba-vpce-s3" }
}
