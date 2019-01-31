provider "aws" {
  region= "us-east-2"
}

variable "serverport"{
  description = "Sets the default port for contacting server"
  default = 8080
}

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

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  
  ingress{
    from_port = "${var.serverport}"
    to_port   = "${var.serverport}"
    protocol  = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }
}
#
#resource "aws_route53_zone" "main"{
#  name = "bradsbox.info"
#}
#resource "aws_route53_zone" "ch2"{
#  name = "ch2.bradsbox.info"
#  tags = {
#    Environment = "ch2"
#  }
#}
#resource "aws_route53_record" "ch2-ns"{
#  zone_id = "${aws_route53_zone.main.zone_id}"
#  name = "ch2.bradsbox.info"
#  type = "NS"
#  ttl = "300"
#
#  records = [
#	"${aws_route53_zone.ch2.name_servers.0}",
#        "${aws_route53_zone.ch2.name_servers.1}",
#        "${aws_route53_zone.ch2.name_servers.2}",
#        "${aws_route53_zone.ch2.name_servers.3}",
#    ]
#}
