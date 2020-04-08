provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "mykey" {
  key_name   = "my-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDkQg9XPzFiVc6U0hnZMUia3QEijQgku5U+vxvO3k6azMdpPLo4BnbVJDw0XTCiiw8SOjMM0T//dNdTNKpKNRCkSrS5YNdD3KMFkCXMiu3oGWcLha9X5gjPV3UsYuTNidRaaDKcQDBZ5qyXn+/8v8eTr3C4vESeVhahjD1Wndih0hBS6ZsqSyrmgLwqu59C2z8AELQGKRcKiHGm9u1EqEtf3YKdz9lm4oYFdewoxgi051p2XAq/2SY9dZHwEZc0aNL4Gm3hVIzLYIVqm0dfg7fG2R2e9c4Cn3slOYK75eRKwRcr+O3z8M9Kp0Ue7JHMUtdqkDoTwtnHBYFQziKsjdP3 ansaryem@gmail.com"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
 

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

#Create the instances

resource "aws_instance" "my-test-instance" {

  ami                    = "ami-0015b9ef68c77328d"
  instance_type          = "t2.micro"
  key_name               = "${aws_key_pair.mykey.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]

  #Instnace tags and count.index refer the above count for no of instance
  tags = {
    Name = "my-instance-1"
  }
}

# Create a S3 bucket
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

# Back-end Configuration To configure Terraform to store the state in your S3 bucket

terraform {
  backend "s3" {
    # Your bucket name!
    bucket         = "ansari-terraform"
    key            = "ansari/s3/terraform.tfstate"
    region         = "us-east-1"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "ansari-terraform-locks"
    encrypt        = true
  }
}
