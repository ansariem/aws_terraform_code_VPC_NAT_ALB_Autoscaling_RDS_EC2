resource "aws_db_instance" "web-app-sql" {
  allocated_storage         = "${var.db_allocate_storage}"
  storage_type              = "${var.db_storage_type}"
  engine                    = "${var.db_engine}"
  engine_version            = "${var.db_engine_version}"
  instance_class            = "${var.db_instance}"
  multi_az                  = "${var.db_multi_az}"
  name                      = "${var.db_end_point_name}"
  username                  = "${var.db_user_id}"
  password                  = "${var.db_password}"
  apply_immediately         = "${var.db_patch_apply_immediately}"
  backup_retention_period   = "${var.db_backup_retention_period}"
  backup_window             = "${var.db_backup_window}"
  skip_final_snapshot       = "${var.db_skip_final_snapshot}"
  final_snapshot_identifier = "${var.db_final_snapshot_identifier}"
  publicly_accessible       = "${var.db_publicly_accessible}"
  deletion_protection       = "${var.db_deletion_protection}"
  db_subnet_group_name      = "${aws_db_subnet_group.web-app-rds-db-subnet.name}"
  vpc_security_group_ids    = ["${aws_security_group.web-app-rds-sg.id}"]
    tags = {
    Name = "${var.db_tag}"
  }
}

resource "aws_db_subnet_group" "web-app-rds-db-subnet" {
  name = "web-app-rds-db-subnet"
  subnet_ids = ["${var.rds_subnet1}","${var.rds_subnet2}"]
}

resource "aws_security_group" "web-app-rds-sg" {
  name = "web-app-rds-sg"
  vpc_id = "${var.vpc_id}"
  
  tags = {
    Name = "Allow_mysql_db"
  }
}

resource "aws_security_group_rule" "web-app-rds-sg-rule" {
  from_port = 3306
  protocol = "tcp"
  security_group_id = "${aws_security_group.web-app-rds-sg.id}"
  to_port = 3306
  type = "ingress"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_rule" {
  from_port = 0
  protocol = "-1"
  security_group_id = "${aws_security_group.web-app-rds-sg.id}"
  to_port = 0
  type = "egress"
  cidr_blocks = ["0.0.0.0/0"]
}