provider "aws" {
  region     = "${var.region}"
}

# VPC Creation
resource "aws_vpc" "prod_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.vpc_tag}"
  }
}

# Creating Internet Gateway
resource "aws_internet_gateway" "prod_gw" {
  vpc_id = "${aws_vpc.prod_vpc.id}"

  tags = {
    Name = "${var.igw_tag}"
  }
}

/*To extend our VPC with this NAT-ed Private network, which required internt access from private instance:
Required following resources VPC, public subnet, private subnet, NAT Gateway
1. NAT Gateway should be available state.
2. Created NAT Gateway on public subnet and Route table should have internet gateway
3. Private subnet route table should have Nat gateway
*/

# Create a EIP for nat_gateway
resource "aws_eip" "nat_gw_eip" {
  vpc = true

  tags = {
    Name = "Web-EIP"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat_gw_eip.id}"
  subnet_id     = "${aws_subnet.public_subnet.0.id}" # need to check

  tags = {
    Name = "Web-NGW"
  }
}

# Private Route Table
resource "aws_route_table" "prod_private" {
  vpc_id = "${aws_vpc.prod_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw.id}"
  }

  tags = {
    Name = "Prod-Private-NATED"
  }
}

# Public Route Table
resource "aws_route_table" "prod_public" {
  vpc_id = "${aws_vpc.prod_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.prod_gw.id}"
  }

  tags = {
    Name = "Public"
  }
}

/*
# Private Route Table
resource "aws_route_table" "prod_private" {
  vpc_id = "${aws_vpc.prod_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.prod_gw.id}"
  }

  tags = {
    Name = "Private"
  }
}*/
#Public Subnet count.index (count = 2 )it will use  only use 2 availability zone

resource "aws_subnet" "public_subnet" {
  count                   = 2
  cidr_block              = "${var.public_cidrs[count.index]}"
  vpc_id                  = "${aws_vpc.prod_vpc.id}"
  availability_zone       = "${var.availability_zone_public[count.index]}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.public_subnet_tag}.${count.index + 1}"
  }
}
#Private Subnet count.index (count = 0 )it will use  only use 2 availability zone

resource "aws_subnet" "private_subnet" {
  count                   = 2
  cidr_block              = "${var.private_cidrs[count.index]}"
  vpc_id                  = "${aws_vpc.prod_vpc.id}"
  availability_zone       = "${var.availability_zone_private[count.index]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.private_subnet_tag}.${count.index + 1}"
  }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  count          = 2
  subnet_id      = "${aws_subnet.public_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.prod_public.id}"
  depends_on     = ["aws_route_table.prod_public", "aws_subnet.public_subnet"]
}

resource "aws_route_table_association" "private_subnet_assoc" {
  count          = 2
  subnet_id      = "${aws_subnet.private_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.prod_private.id}"
  depends_on     = ["aws_route_table.prod_public", "aws_subnet.private_subnet"]
}

# Security Group Creation
resource "aws_security_group" "prod_sg" {
  name        = "prod-sg"
  description = "Allow ssh inbound traffic"
  vpc_id      = "${aws_vpc.prod_vpc.id}"

  tags = {
    Name = "Allow_ssh_http"
  }
}

# Ingress Security Port 22
resource "aws_security_group_rule" "ssh_inbound_access" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.prod_sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http_inbound_access" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.prod_sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# All OutBound Access
resource "aws_security_group_rule" "all_outbound_access" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.prod_sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

