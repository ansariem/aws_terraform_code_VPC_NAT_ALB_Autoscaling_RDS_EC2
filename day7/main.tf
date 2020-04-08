provider "aws" {
  region = "us-east-1"
  }

#module first lab VPC. we can use it for one more vpc if required, only we have to modify the values from the module ony.
module "first_lab_vpc" {
  source             = "./vpc"
  region             = "us-east-1"
  vpc_cidr           = "10.0.0.0/16"
  public_cidrs       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_cidrs      = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  vpc_tag            = "first_lab"
  igw_tag            = "first_lab_igw"
  public_subnet_tag  = "first_lab_public_subnet"
  private_subnet_tag = "first_lab_private_subnet"
}

# My first EC2 LAB

module "first_ec2_lab" {
  source         = "./ec2"
  region         = "us-east-1"
  my_key_name    = "ansarivirginiakey"
  instance_type  = "t2.micro"
  security_group = "${module.first_lab_vpc.security_group_vpc}"
  subnet         = "${module.first_lab_vpc.subnets}"
  iam_profile    = "day7ssm"
  ami            = "ami-04ebc3e86c4d05d87"
  ec2_tag        = "web-lab"
  ec2_count      = "2"
}
# My ALB Module

module "alb" {
  source       = "./alb"
  region       = "us-east-1"
  aws_vpc_id   = "${module.first_lab_vpc.aws_vpc_id}"
  instance1_id = "${module.first_ec2_lab.instance1_id}"
  instance2_id = "${module.first_ec2_lab.instance2_id}"
  subnet1      = "${module.first_lab_vpc.subnet1}"
  subnet2      = "${module.first_lab_vpc.subnet2}"

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
    key            = "ansari/day7/terraform.tfstate"
    region         = "us-east-1"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "ansari-terraform-locks"
    encrypt        = true
  }
}

