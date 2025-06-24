provider "aws" {
  region = var.region
}

#VPC
resource "aws_vpc" "myVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "myVPC"
  }
}

#Subnets

#Public
resource "aws_subnet" "myPublicSubnet" {
    vpc_id = aws_vpc.myVPC.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
      "Name" = "myPublicSubnet"
    }
}

#Private
resource "aws_subnet" "myPrivateSubnet" {
  vpc_id = aws_vpc.myVPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = false
  tags = {
    "Name" = "myPrivateSubnet"
  }
}

#Security groups
#public
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

#private
resource "aws_security_group" "mySGPrivate" {
  name        = "mySGPrivate"
  description = "Allow internal SSH"
  vpc_id      = aws_vpc.myVPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [ aws_security_group.mySGPublic.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "mySGPrivate"
  }
}

#IG
resource "aws_internet_gateway" "myIG" {
    vpc_id = aws_vpc.myVPC.id

    tags = {
      "Name" = "myIG"
    }
}

#EIP
resource "aws_eip" "myNATIP" {
  domain = "vpc"

  tags = {
    Name = "myNATIP"
  }
}

#NAT gateway
resource "aws_nat_gateway" "myNATGateway" {
  allocation_id = aws_eip.myNATIP.id
  subnet_id     = aws_subnet.myPublicSubnet.id

  tags = {
    Name = "myNATGateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.myIG]
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

#Private
resource "aws_route_table" "myRTPrivate" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0" #All outbound traffic
    gateway_id = aws_nat_gateway.myNATGateway.id
  }

  tags = {
    "Name" = "myRTPrivate"
  }
}

resource "aws_instance" "myBastion" {
  ami                         = var.ami_id # Amazon Linux 2 (us-east-1)
  instance_type               = var.instance_type
  //key_name                    = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.myPublicSubnet.id
  vpc_security_group_ids      = [aws_security_group.mySGPublic.id]

  tags = {
    Name = "myBastion"
  }
}

#keypair
resource "aws_instance" "myPrivate" {
  ami                         = var.ami_id # Amazon Linux 2 (us-east-1)
  instance_type               = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.myPrivateSubnet.id
  vpc_security_group_ids      = [aws_security_group.mySGPrivate.id]

  tags = {
    Name = "myPrivate"
  }
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

#Route table association
resource "aws_route_table_association" "myIGAssoc" {
  subnet_id      = aws_subnet.myPublicSubnet.id
  route_table_id = aws_route_table.myRTPublic.id
}

resource "aws_route_table_association" "myNATAssoc" {
  subnet_id      = aws_subnet.myPrivateSubnet.id
  route_table_id = aws_route_table.myRTPrivate.id
}