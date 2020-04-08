provider "aws" {
 # access_key = "${var.aws_access_key}"
 # secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}

data "aws_availability_zones" "available" {
  state = "available"
}
# VPC Creation
resource "aws_vpc" "ansari_main" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ansari-vpc"
  }
}

# Creating Internet Gateway
resource "aws_internet_gateway" "ansari_gw" {
  vpc_id = "${aws_vpc.ansari_main.id}"

  tags = {
    Name = "ansari-igw"
  }
}

# Public Route Table
resource "aws_route_table" "ansari_public" {
  vpc_id = "${aws_vpc.ansari_main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ansari_gw.id}"
  }

  tags = {
    Name = "Public"
  }
}

# Private Route Table
resource "aws_route_table" "ansari_private" {
  vpc_id = "${aws_vpc.ansari_main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ansari_gw.id}"
  }

  tags = {
    Name = "Private"
  }
}
#Public Subnet count.index (count = 0 )it will use  only use 2 availability zone

resource "aws_subnet" "public_subnet" {
  count                   = 3
  cidr_block              = "${var.public_cidrs[count.index]}"
  vpc_id                  = "${aws_vpc.ansari_main.id}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet.${count.index + 1}"
  }
}
#Private Subnet count.index (count = 0 )it will use  only use 2 availability zone

resource "aws_subnet" "private_subnet" {
  count                   = 3
  cidr_block              = "${var.private_cidrs[count.index]}"
  vpc_id                  = "${aws_vpc.ansari_main.id}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "private-subnet.${count.index + 1}"
  }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  count          = 3
  subnet_id      = "${aws_subnet.public_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.ansari_public.id}"
  depends_on     = ["aws_route_table.ansari_public", "aws_subnet.public_subnet"]
}

resource "aws_route_table_association" "private_subnet_assoc" {
  count          = 3
  subnet_id      = "${aws_subnet.private_subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.ansari_private.id}"
  depends_on     = ["aws_route_table.ansari_public", "aws_subnet.private_subnet"]
}

# Security Group Creation
resource "aws_security_group" "ansari_sg" {
  name        = "ansari-sg"
  description = "Allow ssh inbound traffic"
  vpc_id      = "${aws_vpc.ansari_main.id}"

  tags = {
    Name = "Allow_ssh_http"
  }
}

# Ingress Security Port 22
resource "aws_security_group_rule" "ssh_inbound_access" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.ansari_sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http_inbound_access" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.ansari_sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# All OutBound Access
resource "aws_security_group_rule" "all_outbound_access" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.ansari_sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "web" {
  count                  = 3
  ami                    = "ami-04ebc3e86c4d05d87"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.public_subnet[count.index].id}"
  vpc_security_group_ids = ["${aws_security_group.ansari_sg.id}"]
  key_name               = "ansarivirginiakey"
  iam_instance_profile   = "day7ssm"
  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_instance" "db" {
  count                  = 3
  ami                    = "ami-04ebc3e86c4d05d87"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.private_subnet[count.index].id}"
  vpc_security_group_ids = ["${aws_security_group.ansari_sg.id}"]
  key_name               = "ansarivirginiakey"
  iam_instance_profile   = "day7ssm"
  tags = {
    Name = "HelloWorld-db"
  }
}

/*# Create a S3 bucket May be bucket already exist
resource "aws_s3_bucket" "terraform_state" {
  bucket = "ansari-terraform"
  # Enable versioning so we can see the full revision history of our
  # state files

# Basicaly prevent the accidental deletion of S3 bucket
  lifecycle {
    prevent_destroy =true
  }
  versioning {
    enabled = true
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create a DynamoDB table to use for locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "ansari-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
*/

# Back-end Configuration To configure Terraform to store the state in your S3 bucket

terraform {
  backend "s3" {
    # Your bucket name!
    bucket         = "ansari-terraform"
    key            = "ansari/day4/terraform.tfstate"
    region         = "us-east-1"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "ansari-terraform-locks"
    encrypt        = true
    
  }
}