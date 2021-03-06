# S3 Bucket for website
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "website_bucket" {
  bucket = var.domain
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Name      = "${var.domain} Website Bucket"
    Terraform = "true"
  }
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadAccess",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.website.iam_arn}"
      },
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "${aws_s3_bucket.website_bucket.arn}/*"
    }
  ]
}
POLICY
}


# S3 Bucket for Cloudfront logs
# -----------------------------------------------------------------------------

resource "aws_kms_key" "website_logs_encryption_key" {
  description             = "Used to encrypt ${var.domain} website logs bucket"
  deletion_window_in_days = 10
  policy                  = file("policies/logs-bucket-kms-key-policy.json")
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "website_logs" {
  bucket = "${var.domain}-logs"

  # My account
  grant {
    id          = data.aws_canonical_user_id.current_user.id
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }

  # awslogsdelivery account
  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
  grant {
    id          = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
    type        = "CanonicalUser"
    permissions = ["FULL_CONTROL"]
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.website_logs_encryption_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = {
    Name      = "${var.domain} Website Logs"
    Terraform = "true"
  }
}

resource "aws_s3_bucket_public_access_block" "lockdown_website_logs" {
  bucket = aws_s3_bucket.website_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = false
}
