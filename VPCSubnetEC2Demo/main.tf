provider "aws" {
  region = var.region
}

#VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "main_vpc"
  }
}

#Subnet
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = {
    "Name" = "main_subnet"
  }
}

#Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    "Name" = "igw"
  }
}

#Route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0" #All outbound traffic
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "public_rt"
  }
}

#Route table association
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#Security group
resource "aws_security_group" "private_sg" {
  name        = "private_sg"
  description = "Allow internal SSH"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "main_sg"
  }
}

#---------------------Automated EC2 istance creation-----------------
provider "tls" {}

# Step 1: Generate SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Step 2: Save Private Key Locally
resource "local_file" "private_key" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = "${path.module}/id_rsa"
  file_permission      = "0600"
  directory_permission = "0700"
}

# Step 3: Upload Public Key to AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-key-${random_id.suffix.hex}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Random suffix to avoid key name collisions
resource "random_id" "suffix" {
  byte_length = 4
}

# Step 4: Launch EC2 Instance
resource "aws_instance" "example" {
  ami                         = var.ami_id # Amazon Linux 2 (us-east-1)
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.main_subnet.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]

  tags = {
    Name = "TF-SSH-Test"
  }
}

resource "null_resource" "wait_for_ssh" {
  depends_on = [aws_instance.example]

  provisioner "remote-exec" {
    inline = [
      "echo 'EC2 instance is now reachable via SSH'"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.example.public_ip
      private_key = tls_private_key.ssh_key.private_key_pem
      timeout     = "2m"
    }
  }
}

resource "null_resource" "auto_ssh_login" {
  depends_on = [null_resource.wait_for_ssh]

  provisioner "local-exec" {
    command = <<EOT
osascript -e 'tell application "Terminal" to do script "cd ${abspath(path.module)}; ssh -o StrictHostKeyChecking=no -i ./id_rsa ec2-user@${aws_instance.example.public_ip}"'
EOT
    #osascript -e "tell application \\"Terminal\\" to do script \\"cd ${path.module}; ssh -o StrictHostKeyChecking=no -i id_rsa ec2-user@${aws_instance.example.public_ip}\\""
  }
}

# Step 5: Output SSH Command
output "ssh_command" {
  value = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.example.public_ip}"
}
