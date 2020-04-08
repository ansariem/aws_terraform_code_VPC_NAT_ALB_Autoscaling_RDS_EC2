output "aws_vpc_id" {
  value = "${aws_vpc.prod_vpc.id}"
}

output "aws_internet_gw" {
  value = "${aws_internet_gateway.prod_gw.id}"
}

output "security_group_vpc" {
  value = "${aws_security_group.prod_sg.id}"
}
 
output "subnets" {
  value = "${aws_subnet.public_subnet.*.id}"
}

output "private_subnet" {
  value = "${aws_subnet.private_subnet.*.id}"
}

output "subnet1" {
  value = "${element(aws_subnet.public_subnet.*.id, 1)}"
}

output "subnet2" {
  value = "${element(aws_subnet.public_subnet.*.id, 2)}"
}
output "subnet3" {
  value = "${element(aws_subnet.private_subnet.*.id, 1)}"
}
output "subnet4" {
  value = "${element(aws_subnet.private_subnet.*.id, 2)}"
}