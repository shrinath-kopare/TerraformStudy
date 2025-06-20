# VPCSubnetEC2Demo

## Overview

VPCSubnetEC2Demo demonstrates how to provision an AWS VPC, create public and private subnets, and launch EC2 instances within those subnets using Terraform. This project is intended for learning AWS networking and infrastructure automation.

## Features

- Creates a custom VPC
- Sets up public and private subnets
- Configures route tables and an Internet Gateway
- Launches EC2 instances in specified subnets
- Security group configuration for controlled access

## Prerequisites

- AWS account with sufficient permissions
- [Terraform](https://www.terraform.io/downloads.html) installed
- AWS CLI configured (`aws configure`)

## Usage

1. **Initialize Terraform:**
   ```sh
   terraform init
   ```

2. **Review and apply the plan:**
   ```sh
   terraform plan
   terraform apply
   ```

3. **Access EC2 Instances:**
   - Use the output values to find public IPs and connect via SSH.

## Cleanup

To destroy all resources and avoid ongoing charges:
```sh
terraform destroy
```

## Notes

- Never commit sensitive files or credentials to version control.
- Adjust variables as needed in `variables.tf` for your environment.

## License