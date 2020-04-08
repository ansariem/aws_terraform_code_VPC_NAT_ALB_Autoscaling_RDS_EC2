output "aws_vpc_id" {
  value = "${aws_vpc.ansari_main.id}"
}

output "aws_internet_gw" {
  value = "${aws_internet_gateway.ansari_gw.id}"
}

output "security_group_vpc" {
  value = "${aws_security_group.ansari_sg.id}"
}
 
output "subnets" {
  value = "${aws_subnet.public_subnet.*.id}"
}

output "subnet1" {
  value = "${element(aws_subnet.public_subnet.*.id, 1)}"
}

output "subnet2" {
  value = "${element(aws_subnet.public_subnet.*.id, 2)}"
}
output "subnet3" {
  value = "${element(aws_subnet.public_subnet.*.id, 3)}"
}