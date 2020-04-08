provider "aws" {
  region = "us-east-1"
}

#module first lab VPC. we can use it for one more vpc if required, only we have to modify the values from the module ony.
module "first_lab_vpc" {
  source                    = "./vpc"
  region                    = "us-east-1"
  vpc_cidr                  = "10.0.0.0/16"
  public_cidrs              = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs             = ["10.0.4.0/24", "10.0.5.0/24"]
  availability_zone_public  = ["us-east-1a", "us-east-1b"]
  availability_zone_private = ["us-east-1c", "us-east-1d"]
  vpc_tag                   = "first_lab"
  igw_tag                   = "first_lab_igw"
  public_subnet_tag         = "first_lab_public_subnet"
  private_subnet_tag        = "first_lab_private_subnet"
}

# My first EC2 LAB

module "first_ec2_lab" {
  source         = "./ec2"
  region         = "us-east-1"
  my_key_name    = "ansarivirginiakey"
  instance_type  = "t2.micro"
  security_group = module.first_lab_vpc.security_group_vpc
  private_subnet = module.first_lab_vpc.private_subnet
  iam_profile    = "day7ssm"
  ami            = "ami-04ebc3e86c4d05d87"
  ec2_tag        = "web-app-backend"
  ec2_count      = "4"
}

# My ALB Module

module "alb" {
  source                    = "./alb"
  region                    = "us-east-1"
  aws_vpc_id                = module.first_lab_vpc.aws_vpc_id
  subnet1                   = module.first_lab_vpc.subnet1
  subnet2                   = module.first_lab_vpc.subnet2
  key_name                  = "ansarivirginiakey"
  iam_profile               = "day7ssm"
  iam_image                 = "ami-04ebc3e86c4d05d87"
  instance_type             = "t2.micro"
  asg_max                   = "6"
  asg_min                   = "2"
  asg_desired               = "2"
  ec2_tag                   = "web-app-alb"
  schedule_start_time       = "2020-04-09T18:00:00Z"
  schedule_end_time         = "2020-06-04T06:00:00Z"
  schedule_min_size         = "0"
  schedule_max_size         = "1"
  schedule_desired_capacity = "0"
}

# My RDS Module
module "rds" {
  source                       = "./rds"
  db_allocate_storage          = 10
  db_storage_type              = "gp2"
  db_engine                    = "mysql"
  db_engine_version            = "5.7"
  db_instance                  = "db.t2.micro"
  db_end_point_name            = "weblabrds"
  db_user_id                   = "admin"
  db_password                  = "admin123"
  db_backup_retention_period   = 10
  db_backup_window             = "09:46-10:16"
  db_multi_az                  = false
  db_patch_apply_immediately   = "false"
  db_tag                       = "web-app-db"
  db_skip_final_snapshot       = "true"
  db_final_snapshot_identifier = "true"
  db_publicly_accessible       = "true"
  db_deletion_protection       = "false"
  rds_subnet1                  = module.first_lab_vpc.subnet3
  rds_subnet2                  = module.first_lab_vpc.subnet4
  vpc_id                       = module.first_lab_vpc.aws_vpc_id
}

# Create a S3 bucket for Terraform State & Shared Storage for State Files-
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
    bucket = "ansari-terraform"
    key    = "ansari/day13/terraform.tfstate"
    region = "us-east-1"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "ansari-terraform-locks"
    encrypt        = true
  }
}

