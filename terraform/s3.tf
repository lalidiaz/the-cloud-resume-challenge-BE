# ----------------------------- S3 -----------------------------

resource "aws_s3_bucket" "cloud_resume_challenge_laura_diaz" {
  bucket        = "cloud-resume-challenge-laura-diaz"
  force_destroy = true
  tags = {
    Name = "TheCloudResumeChallenge"
  }
}

resource "aws_s3_bucket_cors_configuration" "cloud_resume_challenge_laura_diaz_cors" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id

  cors_rule {
    allowed_origins = [var.domain_name]
    allowed_methods = ["GET", "POST"]
    allowed_headers = ["Content-Type"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_versioning" "cloud_resume_laura_diaz_versioning" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id

  rule {
    id = "cleanup-old-versions"

    filter {
      tag {
        key   = "Name"
        value = "TheCloudResumeChallenge"
      }
    }
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}


resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_block_public_access" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.cloud_resume_challenge_laura_diaz.id
  policy = data.aws_iam_policy_document.cloudfront_s3_access.json
}