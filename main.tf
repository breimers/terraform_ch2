#set cloud service host
provider "aws" {
  region= "us-east-2"
}

#configure serverport
variable "serverport"{
  description = "Sets the default port for contacting server"
  default = 8080
}

#configure elbport
variable "elbport"{
  description = "Sets the default routing port for ELB"
  default = 80
}

#get data on existing domain
data "aws_route53_zone" "selected"{
  name     = "bradsbox.info."
}
#get data on availability zones
data "aws_availability_zones" "all" {}

#setup launch config for ec2 micro instances
resource "aws_launch_configuration" "ch2test" {
  image_id        = "ami-40d4f025"
  instance_type   ="t2.micro"
  security_groups =["${aws_security_group.instance.id}"]
  user_data = <<-EOF
	    #!/bin/bash
	    echo "Hello, World!" > index.html
	    nohup busybox httpd -f -p "${var.serverport}" &
	    EOF
  lifecycle {
    create_before_destroy = true
  }
}

#provision ASG for webserver
resource "aws_autoscaling_group" "ch2test" {
  launch_configuration = "${aws_launch_configuration.ch2test.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]
  load_balancers       = ["${aws_elb.ch2test.name}"]
  health_check_type    = "ELB"
  min_size = 2
  max_size = 6
  tag {
    key                 = "Name"
    value               = "terraform-asg-ch2ex"
    propagate_at_launch = true
  }
}

#link dynamic instances with load balancer
resource "aws_elb" "ch2test" {
  name               = "terraform-asg-ch2ex"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.elb.id}"]
  #route traffic from listener port to instances
  listener {
    lb_port           = "${var.elbport}"
    lb_protocol       = "http"
    instance_port     = "${var.serverport}"
    instance_protocol = "http"
  }
  #perform a healthcheck and redirect traffic
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 60
    target              = "HTTP:${var.serverport}/"
  }
}

#accept all traffic from serverport
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress{
    from_port = "${var.serverport}"
    to_port   = "${var.serverport}"
    protocol  = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }
  lifecycle{
    create_before_destroy = true
  }
}

#accept all traffic from elb port
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  ingress{
    from_port      = "${var.elbport}"
    to_port        = "${var.elbport}"
    protocol       = "tcp"
    cidr_blocks    =["0.0.0.0/0"]
  }
  egress{
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#created record from existing host zone
resource "aws_route53_record" "www" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${data.aws_route53_zone.selected.name}"
  type    = "A"
  alias {
    name            ="${aws_elb.ch2test.dns_name}"
    zone_id         ="${aws_elb.ch2test.zone_id}"
    evaluate_target_health = true
  }
}
