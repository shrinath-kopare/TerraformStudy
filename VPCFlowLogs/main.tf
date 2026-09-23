#region Shared Configuration
# This module is used to share common configurations like region, instance type, and AMI ID
# across different Terraform modules.
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
#endregion

#region Public Subnet Setup
#VPC
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name" = "myVPC"
  }
}

#Subnets
#Public
resource "aws_subnet" "myPublicSubnet" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-south-1a"
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

  tags = {
    "Name" = "myRTPublic"
  }
}

#Route table association
resource "aws_route_table_association" "myIGAssoc" {
  subnet_id      = aws_subnet.myPublicSubnet.id
  route_table_id = aws_route_table.myRTPublic.id
}

#endregion

#region Bastion Host Setup
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
#endregion

#region SSH Key Pair Generation and Upload
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
#endregion

#region S3 VPC Flow Logs
#Create S3 bucket
resource "aws_s3_bucket" "vpc_flow_logs_s3" {
  bucket = "vpc-flow-logs-bucket-${random_id.suffix.hex}"
}

#Set ownership
# resource "aws_s3_bucket_ownership_controls" "vpc_flow_logs_s3" {
#   bucket = aws_s3_bucket.vpc_flow_logs_s3.id
#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

# #Set access
# resource "aws_s3_bucket_acl" "vpc_flow_logs_s3" {
#   depends_on = [aws_s3_bucket_ownership_controls.vpc_flow_logs_s3]

#   bucket = aws_s3_bucket.vpc_flow_logs_s3.id
#   acl    = "private"
# }

#set the vpc flow log
resource "aws_flow_log" "vpc_flow_logs_s3" {
  log_destination      = aws_s3_bucket.vpc_flow_logs_s3.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.myVPC.id
}
#endregion

#region CloudWatch VPC Flow Logs
#Create CloudWatch log group
resource "aws_cloudwatch_log_group" "vpc_flow_logs_cw" {
  name              = "vpc-flow-logs-${random_id.suffix.hex}"
  retention_in_days = 1
}

#Create VPC Flow Log
resource "aws_flow_log" "vpc_flow_logs_cw" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs_cw.arn
  iam_role_arn    = aws_iam_role.example.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.myVPC.id       
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example" {
  name               = "example"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"

    actions = ["*"]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "example" {
  name   = "example"
  role   = aws_iam_role.example.id
  policy = data.aws_iam_policy_document.example.json
}
#endregion

