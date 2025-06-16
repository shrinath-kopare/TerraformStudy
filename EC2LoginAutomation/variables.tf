variable "ami_id" {
  default = "ami-0dee22c13ea7a9a67" #Ubuntu free tier ami
  description = "AMI to be used for EC2"
}

variable "instance_type" {
  default = "t2.micro"
  description = "Instance type to be used for EC2"
}

variable "region" {
  default = "ap-south-1"
  description = "Region"
}