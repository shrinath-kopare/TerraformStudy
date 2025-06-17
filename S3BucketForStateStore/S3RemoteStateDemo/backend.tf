terraform {
  backend "s3" {
    bucket         = "shrinath-tf-state-backup"
    key            = "S3RemoteStateDemo/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "shrinath-tf-state-backup-lock"
    encrypt        = true
  }
}