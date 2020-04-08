# AWS Region
variable "region" {}

variable "vpc_cidr" {}
variable "public_cidrs" {
  type    = "list"
}

variable "private_cidrs" {
  type    = "list"
}

variable "availability_zone_public" {
  type    = "list"
}
variable "availability_zone_private" {
  type    = "list"
}
variable "vpc_tag" {}

variable "igw_tag" {}

variable "public_subnet_tag" {}

variable "private_subnet_tag" {}