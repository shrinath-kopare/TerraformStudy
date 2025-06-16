provider "aws" {
  region = var.region
}

# Create a Security Group that allows SSH access
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows SSH from anywhere; restrict to your IP for better security.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data              = file("./script/add-ssh-web-app.yaml")

  tags = {
    Name = "MyAutomatedEC2"
  }

  # Automatically get the public IP
  associate_public_ip_address = true
}

# Output the instance's public IP
output "public_ip" {
  value = aws_instance.ec2_instance.public_ip
}

output "connect" {
  value = "Run: ./sshconnect.sh to connect to EC2 using ssh"
}

