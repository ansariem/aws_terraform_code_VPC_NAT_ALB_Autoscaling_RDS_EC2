# Aadding provider here for testing locally

provider "aws" {
   region = "${var.region}"
}

# Target LB Group
resource "aws_lb_target_group" "web_app_target_group" {

 health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
  }

  name                  = "we-app-lb-tg"
  port                  = 80
  protocol              = "HTTP"
  target_type           = "instance"  # It can be IP or Instance or Lambda 
  load_balancing_algorithm_type = "least_outstanding_requests"
  vpc_id                = "${var.aws_vpc_id}"
}

# Launch Configuration

# *.tpl for for install and configure steps after instence spin up

data "template_file" "pkg_init" {
  template = "${file("${path.module}/install_userdata.tpl")}"
}

resource "aws_launch_configuration" "web_app_cf" {
  name                   = "web_app_config"
  image_id               = "${var.iam_image}"
  instance_type          = "${var.instance_type}"
  security_groups        = ["${aws_security_group.web_app_alb_sg.id}"]
  key_name               = "${var.key_name}"
  iam_instance_profile   = "${var.iam_profile}"
  user_data              =  "${data.template_file.pkg_init.rendered}"
  
      # Required to redeploy without an outage.
    lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "web_app_asg" {
  name                 = "web-app-asg"
  launch_configuration = "${aws_launch_configuration.web_app_cf.name}"
  vpc_zone_identifier  =  ["${var.subnet1}","${var.subnet2}"]
  target_group_arns    =  ["${aws_lb_target_group.web_app_target_group.arn}"] 
  health_check_type    = "ELB"
  min_size             = "${var.asg_min}"
  max_size             = "${var.asg_max}"
  desired_capacity     = "${var.asg_desired}"
  health_check_grace_period = 120
  termination_policies = ["OldestInstance"]

    tag {
    key                 = "Name"
    value               = "${var.ec2_tag}"
    propagate_at_launch = true
  }

    lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_schedule" "web_app_asg" {
  scheduled_action_name  = "web_app_asg"
  min_size               = "${var.schedule_min_size}"
  max_size               = "${var.schedule_max_size}"
  desired_capacity       = "${var.schedule_desired_capacity}"
  start_time             = "${var.schedule_start_time}"  
  end_time               = "${var.schedule_end_time}"   
  autoscaling_group_name = "${aws_autoscaling_group.web_app_asg.name}"
}

# Scale up policy
resource "aws_autoscaling_policy" "web_app_scale_up" {
    name                    = "web-app-scale-up"
    scaling_adjustment      = 2
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 180
    policy_type             = "SimpleScaling"
    autoscaling_group_name  = "${aws_autoscaling_group.web_app_asg.name}"
}

# Scale down Policy
resource "aws_autoscaling_policy" "web_app_scale_down" {
    name                    = "web-app-scale-down"
    scaling_adjustment      = -2
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 180
    policy_type             = "SimpleScaling"
    autoscaling_group_name  = "${aws_autoscaling_group.web_app_asg.name}"
}

#cloud watch Alarm metrix Scale up metrix
resource "aws_cloudwatch_metric_alarm" "cpu-high" {
    alarm_name              = "cpu-util-high-web_app"
    comparison_operator     = "GreaterThanOrEqualToThreshold"
    evaluation_periods      = "2"
    metric_name             = "CPUUtilization" #"MemoryUtilization"
    namespace               = "System/Linux"
    period                  = "60"
    statistic               = "Average"
    threshold               = "30"
    alarm_description       = "This metric monitors ec2 cpu for high utilization on web_app hosts"
    alarm_actions           = [
        "${aws_autoscaling_policy.web_app_scale_up.arn}"
    ]

    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.web_app_asg.name}"
    }
}

#cloud watch Alarm metrix Scale down metrix
resource "aws_cloudwatch_metric_alarm" "cpu-low" {
    alarm_name              = "cpu-util-low-web_app"
    comparison_operator     = "LessThanOrEqualToThreshold"
    evaluation_periods      = "2"
    metric_name             = "CPUUtilization" #"MemoryUtilization"
    namespace               = "System/Linux"
    period                  = "120"
    statistic               = "Average"
    threshold               = "10"
    alarm_description       = "This metric monitors ec2 cpu for low utilization on web_app hosts"
    alarm_actions           = [
        "${aws_autoscaling_policy.web_app_scale_down.arn}"
    ]

    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.web_app_asg.name}"
    }
}
# Create the Actual LB

resource "aws_lb" "web_app_alb" {
  name               = "web-app-lb"
  internal           = false
  security_groups    = ["${aws_security_group.web_app_alb_sg.id}"]
  subnets            = ["${var.subnet1}","${var.subnet2}"]  # need to check
  #enable_deletion_protection = true
  tags = {
    Name = "Prod"
  }
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
}

# Aws LB listener.

resource "aws_lb_listener" "web_app_alb_listner" {
  load_balancer_arn = "${aws_lb.web_app_alb.arn}"
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.web_app_target_group.arn}"
  }
}

# Create a Security Group for ALB

#security groups for ALB
resource "aws_security_group" "web_app_alb_sg" {
  name   = "web-app-alb-sg"
  vpc_id = "${var.aws_vpc_id}"

  tags = {
    Name = "ALB_allow_ssh_http"
  }
}

resource "aws_security_group_rule" "web_app_inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.web_app_alb_sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# security groups policy
resource "aws_security_group_rule" "web_app_inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.web_app_alb_sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_app_outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.web_app_alb_sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
