output "aws_vpc_id" {
  value = "${aws_vpc.ansari_main.id}"
}

output "aws_internet_gw" {
  value = "${aws_internet_gateway.ansari_gw.id}"
}
