# Aadding provider here for testing locally

provider "aws" {
   region = "${var.region}"
}

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
  vpc_id                = "${var.aws_vpc_id}"
}

# Attache the already running Instance into ALB.

resource "aws_lb_target_group_attachment" "my_alb_target_group_attachment1" {
  target_group_arn = "${aws_lb_target_group.web_app_target_group.arn}"
  target_id        = "${var.instance1_id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "my_alb_target_group_attachment2" {
  target_group_arn = "${aws_lb_target_group.web_app_target_group.arn}"
  target_id        = "${var.instance2_id}"
  port             = 80
}


resource "aws_lb_target_group_attachment" "my_alb_target_group_attachment3" {
  target_group_arn = "${aws_lb_target_group.web_app_target_group.arn}"
  target_id        = "${var.instance3_id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "my_alb_target_group_attachment4" {
  target_group_arn = "${aws_lb_target_group.web_app_target_group.arn}"
  target_id        = "${var.instance4_id}"
  port             = 80
}


resource "aws_lb_target_group_attachment" "my_alb_target_group_attachment5" {
  target_group_arn = "${aws_lb_target_group.web_app_target_group.arn}"
  target_id        = "${var.instance5_id}"
  port             = 80
}

resource "aws_lb_target_group_attachment" "my_alb_target_group_attachment6" {
  target_group_arn = "${aws_lb_target_group.web_app_target_group.arn}"
  target_id        = "${var.instance6_id}"
  port             = 80
}
# Create the Actual LB

resource "aws_lb" "web_app_alb" {
  name               = "web-app-lb"
  internal           = false
  security_groups    = ["${aws_security_group.web_app_alb_sg.id}"]
  subnets            = ["${var.subnet1}","${var.subnet2}","${var.subnet3}"]  # need to check
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
