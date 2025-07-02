provider "aws" {
  region = var.region
}

#VPC
resource "aws_vpc" "myVPC" {
  cidr_block = "10.10.0.0/16"
  tags = {
    "Name" = "myVPC"
  }
}

#IG
resource "aws_internet_gateway" "myIG" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    "Name" = "myIG"
  }
}

#Route tables
#Public
resource "aws_route_table" "myRTPublic" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0" #All outbound traffic
    gateway_id = aws_internet_gateway.myIG.id
  }

  tags = {
    "Name" = "myRTPublic"
  }
}

#pulic Subnet
resource "aws_subnet" "myPublicSubnet" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "myPublicSubnet"
  }

}

#Route table association
resource "aws_route_table_association" "myIGAssoc" {
  subnet_id      = aws_subnet.myPublicSubnet.id
  route_table_id = aws_route_table.myRTPublic.id
}

#SG
resource "aws_security_group" "mySGPublic" {
  name        = "mySGPublic"
  description = "Allow public SSH"
  vpc_id      = aws_vpc.myVPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
    "Name" = "mySGPublic"
  }
}

#NACL
resource "aws_network_acl" "myNACL" {
  vpc_id = aws_vpc.myVPC.id

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }


  tags = {
    "Name" = "myNACL"
  }
}

resource "aws_network_acl_association" "myNACLAssoc" {
  subnet_id       = aws_subnet.myPublicSubnet.id
  network_acl_id  = aws_network_acl.myNACL.id
}

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
  subnet_id                   = aws_subnet.myPublicSubnet.id
  security_groups             = [aws_security_group.mySGPublic.id]

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

