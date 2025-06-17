# S3BucketForStateStore

This project demonstrates how to set up an AWS S3 bucket and DynamoDB table for use as a remote backend for Terraform state storage and state locking.

## Structure

- **S3Setup/**: Terraform configuration to create the S3 bucket and DynamoDB table.
- **S3RemoteStateDemo/**: Example of configuring Terraform to use the remote backend.

## Usage

### 1. Deploy S3 Bucket and DynamoDB Table

Navigate to the `S3Setup` directory and initialize/apply Terraform:

```sh
cd S3BucketForStateStore/S3Setup
terraform init
terraform apply
```

This will create:
- An S3 bucket (`shrinath-tf-state-backup`) for storing Terraform state files.
- A DynamoDB table (`shrinath-tf-state-backup-lock`) for state locking.

### 2. Configure Remote State in Other Projects

Use the backend configuration as shown in [`S3RemoteStateDemo/backend.tf`](S3BucketForStateStore/S3RemoteStateDemo/backend.tf):

```hcl
terraform {
  backend "s3" {
    bucket         = "shrinath-tf-state-backup"
    key            = "S3RemoteStateDemo/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "shrinath-tf-state-backup-lock"
    encrypt        = true
  }
}
```

### 3. Example: Using the Remote Backend

Navigate to `S3RemoteStateDemo` and run:

```sh
cd ../S3RemoteStateDemo
terraform init
terraform apply
```

## Outputs

- **s3_bucket_arn**: ARN of the created S3 bucket.
- **dynamodb_table_name**: Name of the DynamoDB table for state locking.

## Notes

- Ensure you have AWS credentials configured.
- Never commit sensitive files or credentials to version control