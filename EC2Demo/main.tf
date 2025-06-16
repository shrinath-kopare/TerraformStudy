provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "name" {
  count = 2
  ami = "ami-0dee22c13ea7a9a67"
  instance_type = "t2.micro"


  tags = {
    Name = "my-instance-${count.index}"
  }
}

output "instance_public_ips" {
  value = aws_instance.name.*.public_ip
}