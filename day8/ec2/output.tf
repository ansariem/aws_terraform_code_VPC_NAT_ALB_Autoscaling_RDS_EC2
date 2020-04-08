output "instance1_id" {
  value = "${element(aws_instance.web.*.id, 1)}"
}
output "instance2_id" {
  value = "${element(aws_instance.web.*.id, 2)}"
}

output "instance3_id" {
  value = "${element(aws_instance.web.*.id, 3)}"
}
output "instance4_id" {
  value = "${element(aws_instance.web.*.id, 4)}"
}
output "instance5_id" {
  value = "${element(aws_instance.web.*.id, 5)}"
}
output "instance6_id" {
  value = "${element(aws_instance.web.*.id, 6)}"
}