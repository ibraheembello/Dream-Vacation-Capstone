# Part 1: networking. Mirrors the Stage 6 CLI build, now as code.
#   dream-vpc (10.0.0.0/16) -> dream-subnet (10.0.1.0/24)
#   dream-igw + dream-rt with a default route out, associated to the subnet.

resource "aws_vpc" "dream" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dream-vpc"
  }
}

resource "aws_subnet" "dream" {
  vpc_id                  = aws_vpc.dream.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "dream-subnet"
  }
}

resource "aws_internet_gateway" "dream" {
  vpc_id = aws_vpc.dream.id

  tags = {
    Name = "dream-igw"
  }
}

resource "aws_route_table" "dream" {
  vpc_id = aws_vpc.dream.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dream.id
  }

  tags = {
    Name = "dream-rt"
  }
}

resource "aws_route_table_association" "dream" {
  subnet_id      = aws_subnet.dream.id
  route_table_id = aws_route_table.dream.id
}
