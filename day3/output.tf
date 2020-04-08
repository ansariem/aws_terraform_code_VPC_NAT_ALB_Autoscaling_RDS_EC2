output "aws_vpc_id" {
  value = "${aws_vpc.ansari_main.id}"
}

output "aws_internet_gw" {
  value = "${aws_internet_gateway.ansari_gw.id}"
}
output "aws_public_subnet-1" {
  value = "${aws_subnet.public_cidr-1}"
}


output "aws_public_subnet-2" {
  value = "${aws_subnet.public_cidr-2}"
}


output "aws_private_subnet-1" {
  value = "${aws_subnet.private_cidr-1.id}"
}


output "aws_private_subnet-2" {
  value = "${aws_subnet.private_cidr-2}"
}
