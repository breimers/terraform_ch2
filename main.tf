provider "aws" {
  region= "us-east-2"
}

resource "aws_instance" "ch2test" {
  ami	= "ami-40d4f025"
  instance_type ="t2.micro"
  tags {
    Name = "terraform-example"
  }
}


