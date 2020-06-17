# Backend
# -----------------------------------------------------------------------------

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "rosstimson"

    workspaces {
      name = "hashbangwallop"
    }
  }
}

# Provider
# -----------------------------------------------------------------------------

provider "aws" {
  region  = var.region
  version = "~> 2.66"
}

# Cloudfront ACM certs must exist in US-East-1 for use with Cloudfront.
provider "aws" {
  alias   = "acm"
  region  = "us-east-1"
  version = "~> 2.66"
}
