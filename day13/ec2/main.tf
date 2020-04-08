provider "aws" {
   region = "${var.region}"
}

# *.tpl for for install and configure steps after instence spin up

data "template_file" "pkg_init" {
  template = "${file("${path.module}/install_userdata.tpl")}"
}


resource "aws_instance" "web" {
  count                  = "${var.ec2_count}"
  ami                    = "${var.ami}"
  instance_type          = "${var.instance_type}"
  subnet_id              = "${element(var.private_subnet, count.index)}"
  vpc_security_group_ids = ["${var.security_group}"]
  key_name               = "${var.my_key_name}"
  iam_instance_profile   = "${var.iam_profile}"
  user_data              =  "${data.template_file.pkg_init.rendered}"
  tags = {
    Name = "${var.ec2_tag}" #-${count.index + 1}"
  }
}

