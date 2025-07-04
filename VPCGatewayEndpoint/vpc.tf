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

# aws_vpc.myVPC:
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = false
  tags = {
    "Name" = "myVPC"
  }
}

# aws_subnet.myPrivateSubnet:
resource "aws_subnet" "myPrivateSubnet" {
  vpc_id            = aws_vpc.myVPC.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    "Name" = "myPrivateSubnet"
  }
}

# aws_subnet.myPublicSubnet:
resource "aws_subnet" "myPublicSubnet" {
  vpc_id            = aws_vpc.myVPC.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    "Name" = "myPublicSubnet"
  }
}

#Route table association
resource "aws_route_table_association" "myIGAssoc" {
  subnet_id      = aws_subnet.myPublicSubnet.id
  route_table_id = aws_route_table.myPublicRT.id
}

#Route table association
resource "aws_route_table_association" "myIGAssoc1" {
  subnet_id      = aws_subnet.myPrivateSubnet.id
  route_table_id = aws_route_table.myPrivateRT.id
}

# aws_vpc_endpoint.myGatewayEndpoint:
resource "aws_vpc_endpoint" "myGatewayEndpoint" {
  vpc_id            = aws_vpc.myVPC.id
  service_name      = "com.amazonaws.ap-south-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.myPrivateRT.id
  ]
  tags = {
    "Name" = "myGatewayEndpoint"
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "myKey" {
  key_name = "myKey-${formatdate("YYYYMMDD-HHmm", timestamp())}"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "save_private_key" {
  content         = tls_private_key.example.private_key_pem
  filename        = "${path.module}/my-key.pem"
  file_permission = "0400"
}

# aws_instance.myPrivateInstance:
resource "aws_instance" "myPrivateInstance" {
  ami                    = local.ami_id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.myPrivateSubnet.id
  key_name               = aws_key_pair.myKey.key_name
  iam_instance_profile   = aws_iam_instance_profile.myS3Profile.name
  vpc_security_group_ids = [aws_security_group.mySGPrivate.id]

  tags = {
    "Name" = "myPrivateInstance"
  }
}

# aws_instance.myBastionHost:
resource "aws_instance" "myBastionHost" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.myPublicSubnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mySGPublic.id]

  tags = {
    "Name" = "BastionHost"
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
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.mySGPublic.id]
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

# aws_internet_gateway.myIG:
resource "aws_internet_gateway" "myIG" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    "Name" = "myIG"
  }
}

# aws_route_table.myPrivateRT:
resource "aws_route_table" "myPrivateRT" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    "Name" = "myPrivateRT"
  }
}

# aws_route_table.myPublicRT:
resource "aws_route_table" "myPublicRT" {
  vpc_id = aws_vpc.myVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIG.id
  }
  tags = {
    "Name" = "myPublicRT"
  }
}

# aws_iam_role.myS3Role:
resource "aws_iam_role" "myS3Role" {
  name = "myS3Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  description = "Allows EC2 instances to call AWS services on your behalf."
  path        = "/"
}

resource "aws_iam_role_policy_attachment" "myS3Role_s3_readonly" {
  role       = aws_iam_role.myS3Role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "myS3Profile" {
  name = "myS3Profile"
  role = aws_iam_role.myS3Role.name
}

resource "aws_s3_bucket" "example" {
  bucket = "my-s3-bucket-${formatdate("YYYYMMDD-HHmm", timestamp())}"
  tags = {
    Name        = "myS3Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.example.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.example]

  bucket = aws_s3_bucket.example.id
  acl    = "private"
}