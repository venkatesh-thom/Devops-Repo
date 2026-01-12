resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "terraform-day15-prod-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "MyBucket"
    Environment = "Production"
  }
}

### Keeps multiple versions of same object of file.txt (v1), file.txt(v2)
resource "aws_s3_bucket_versioning" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}





### Ownership Controls ###
resource "aws_s3_bucket_ownership_controls" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# 👉 Why this exists becasue it's Controls who owns uploaded objects.

# 👉 BucketOwnerPreferred

# If someone else uploads object:
# 👉 Bucket owner still owns it


### Bucket ACL [Only bucket owner can access]
resource "aws_s3_bucket_acl" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.my_bucket]
}


#### Block All Public Access

resource "aws_s3_bucket_public_access_block" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### Server-Side Encryption

resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
