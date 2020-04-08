output "instance1_id" {
  value = "${element(aws_instance.web.*.id, 1)}"
}
output "instance2_id" {
  value = "${element(aws_instance.web.*.id, 2)}"
}
