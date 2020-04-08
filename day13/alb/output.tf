 
output "alb_dns_name" {
  value = "${aws_lb.web_app_alb.dns_name}"
}

output "alb_target_group_arn" {
  value = "${aws_lb_target_group.web_app_target_group.arn}"
}