# For non-root domain (i.e. the www. alias).
resource "aws_route53_record" "cdn_cname" {
  zone_id = data.aws_route53_zone.zone.id
  name    = var.domain_alias
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_cloudfront_distribution.website_cdn.domain_name}"]
}

# For the root domain.
resource "aws_route53_record" "cdn_alias" {
  zone_id = data.aws_route53_zone.zone.id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.website_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
