provider "aws" {
  region = "ap-south-1"
}

resource "aws_ebs_volume" "my_ebs_volume" {
  availability_zone = "ap-south-1a"
  size              = 1
  type              = "gp2"
  tags = {
    Name = "my-ebs-volume"
  }
}