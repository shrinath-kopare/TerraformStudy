provider "aws" {
  region = var.region  # Change as needed
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
  ami                    = var.ami_id  # Amazon Linux 2 (us-east-1)
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true

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