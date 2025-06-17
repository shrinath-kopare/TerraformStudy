#Create S3 bucket
resource "aws_s3_bucket" "shrinath-tf-state-backup" {
  bucket = "shrinath-tf-state-backup"
}

#Set ownership
resource "aws_s3_bucket_ownership_controls" "shrinath-tf-state-backup" {
  bucket = aws_s3_bucket.shrinath-tf-state-backup.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Set access
resource "aws_s3_bucket_acl" "shrinath-tf-state-backup" {
  depends_on = [aws_s3_bucket_ownership_controls.shrinath-tf-state-backup]

  bucket = aws_s3_bucket.shrinath-tf-state-backup.id
  acl    = "private"
}

#upload test
# resource "aws_s3_object" "object" {
#   for_each = fileset("uploads/", "*")
#   bucket = aws_s3_bucket.shrinath-tf-state-backup.id
#   key    = each.value
#   source = "uploads/${each.value}"

#   # The filemd5() function is available in Terraform 0.11.12 and later
#   # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
#   # etag = "${md5(file("path/to/file"))}"
# #   etag = filemd5("path/to/file")
# }

resource "aws_s3_bucket_public_access_block" "app" {
    bucket = aws_s3_bucket.shrinath-tf-state-backup.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.shrinath-tf-state-backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add bucket encryption to hide sensitive state data
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.shrinath-tf-state-backup.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "shrinath-tf-state-backup-lock" {
  name         = "shrinath-tf-state-backup-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.shrinath-tf-state-backup.arn
  description = "The ARN of the S3 bucket"
}
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.shrinath-tf-state-backup-lock.name
  description = "The name of the DynamoDB table"
}