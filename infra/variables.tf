variable "region" {
  description = "The AWS region. Example: eu-west-1"
}

variable "domain" {
  description = "The domain name for website. Example: rosstimson.com"
}

variable "domain_alias" {
  description = "Domain name alias for website. Example: www.rosstimson.com"
}

variable "forward_query_string" {
  description = "Forward the query string to the origin."
  default     = false
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  default     = "PriceClass_200"
}
