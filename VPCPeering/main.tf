module "shared_config" {
  source = "../shared"
}

locals {
  region        = module.shared_config.region
  instance_type = module.shared_config.instance_type
  ami_id        = module.shared_config.ami_id
}

provider "aws" {
  region = local.region
}

#VPC
resource "aws_vpc" "myVPC" {
  cidr_block = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "myVPC"
  }
}

#Subnets

#Public
resource "aws_subnet" "myPublicSubnet" {
    vpc_id = aws_vpc.myVPC.id
    cidr_block = "10.10.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
      "Name" = "myPublicSubnet"
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

    ingress {
    from_port   = 8080
    to_port     = 8080
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

  route {
    cidr_block = "172.32.0.0/16" #All outbound traffic
    vpc_peering_connection_id = aws_vpc_peering_connection.myVPCPeering.id
  }

  tags = {
    "Name" = "myRTPublic"
  }
}

resource "aws_instance" "myBastion" {
  ami                         = local.ami_id # Amazon Linux 2 (us-east-1)
  instance_type               = local.instance_type
  key_name                    = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.myPublicSubnet.id
  vpc_security_group_ids      = [aws_security_group.mySGPublic.id]

  tags = {
    Name = "myBastion"
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


# ------------------------------------------------------------------------------------------

#VPC
resource "aws_vpc" "myVPC2" {
  cidr_block = "172.32.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "myVPC2"
  }
}

#Subnets

#Public
resource "aws_subnet" "myPublicSubnet2" {
    vpc_id = aws_vpc.myVPC2.id
    cidr_block = "172.32.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
      "Name" = "myPublicSubnet2"
    }
}

#Security groups
#public
resource "aws_security_group" "mySGPublic2" {
  name        = "mySGPublic2"
  description = "Allow public SSH"
  vpc_id      = aws_vpc.myVPC2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 8080
    to_port     = 8080
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
    "Name" = "mySGPublic2"
  }
}

#IG
resource "aws_internet_gateway" "myIG2" {
    vpc_id = aws_vpc.myVPC2.id

    tags = {
      "Name" = "myIG2"
    }
}

#Route tables
#Public
resource "aws_route_table" "myRTPublic2" {
  vpc_id = aws_vpc.myVPC2.id

  route {
    cidr_block = "0.0.0.0/0" #All outbound traffic
    gateway_id = aws_internet_gateway.myIG2.id
  }

  route {
    cidr_block = "10.10.1.0/24" #All outbound traffic
    vpc_peering_connection_id = aws_vpc_peering_connection.myVPCPeering.id
  }

  tags = {
    "Name" = "myRTPublic2"
  }
}

resource "aws_instance" "myBastion2" {
  ami                         = local.ami_id # Amazon Linux 2 (us-east-1)
  instance_type               = local.instance_type
  key_name                    = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.myPublicSubnet2.id
  vpc_security_group_ids      = [aws_security_group.mySGPublic2.id]

  tags = {
    Name = "myBastion2"
  }
}

#Route table association
resource "aws_route_table_association" "myIGAssoc2" {
  subnet_id      = aws_subnet.myPublicSubnet2.id
  route_table_id = aws_route_table.myRTPublic2.id
}

#vpc peering connection
resource "aws_vpc_peering_connection" "myVPCPeering" {
  vpc_id        = aws_vpc.myVPC2.id
  peer_vpc_id   = aws_vpc.myVPC.id # Replace with the actual VPC ID you want to peer with
  auto_accept   = true
  tags = {
    Name = "myVPCPeeringConnection"
  }
}
