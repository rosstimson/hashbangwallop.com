# Cloudfront
# -----------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_identity" "website" {
  comment = "cf-access-identity-for-${var.domain}"
}

locals {
  s3_origin_id = "origin-bucket-${aws_s3_bucket.website_bucket.id}"
}

resource "aws_cloudfront_distribution" "website_cdn" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Hash Bang Wallop website CDN"
  price_class     = var.cloudfront_price_class

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.website_logs.bucket_domain_name
    prefix          = "cf-logs/"
  }

  origin {
    origin_id   = local.s3_origin_id
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website.cloudfront_access_identity_path
    }
  }

  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    // This redirects any HTTP request to HTTPS.
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.ssl_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  aliases = ["${var.domain}", "${var.domain_alias}"]

  tags = {
    Name      = "${var.domain} Website CDN"
    Terraform = "true"
  }
}
