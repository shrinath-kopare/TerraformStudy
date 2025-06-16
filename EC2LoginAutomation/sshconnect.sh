#!/bin/bash

# Get the public IP using Terraform output
public_ip=$(terraform output -raw public_ip)

# Run the SSH command
ssh terraform@$public_ip -i tf-cloud-init

