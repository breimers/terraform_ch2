#set cloud service host
provider "aws" {
  region= "us-east-2"
}

#configure serverport
variable "serverport"{
  description = "Sets the default port for contacting server"
  default = 8080
}

#get data on existing domain
data "aws_route53_zone" "selected"{
  name     = "bradsbox.info."
}

#provision ec2 instance on t2.micro
resource "aws_instance" "ch2test" {
  ami	= "ami-40d4f025"
  instance_type ="t2.micro"
  vpc_security_group_ids=["${aws_security_group.instance.id}"]
  tags {
    Name = "terraform-example"
  }
  
  user_data = <<-EOF
	    #!/bin/bash
	    echo "Hello, World!" > index.html
	    nohup busybox httpd -f -p "${var.serverport}" &
	    EOF
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
}

#created record from existing host zone
resource "aws_route53_record" "www" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.ch2test.public_ip}"]
}
