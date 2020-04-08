provider "aws" {
  region     = "${var.region}"
}

/*data "aws_availability_zones" "available" {
  state = "available" 
} */
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
}
#Public Subnet count.index (count = 0 )it will use  only use 2 availability zone

resource "aws_subnet" "public_subnet" {
  count                   = 2
  cidr_block              = "${var.public_cidrs[count.index]}"
  vpc_id                  = "${aws_vpc.prod_vpc.id}"
  #availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  availability_zone       = "${var.availbility_zone_public[count.index]}"
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
  #availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
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

