variable "ami_id" {
  default = "ami-0b09627181c8d5778" #Ubuntu free tier ami
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

output "region" {
  value = var.region  
}

output "ami_id" {
  value = var.ami_id
}

output "instance_type" {
  value = var.instance_type
}


