# ----------------------------- Cloudfront -----------------------------

resource "aws_cloudfront_origin_access_control" "cloudfront_origin_access" {
  name                              = "cloudfront_origin_access"
  description                       = "Manages an AWS CloudFront Origin Access Control, which is used by CloudFront Distributions with an Amazon S3 bucket as the origin."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.cloud_resume_challenge_laura_diaz.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.cloud_resume_challenge_laura_diaz.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_origin_access.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${aws_s3_bucket.cloud_resume_challenge_laura_diaz.id}"
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = aws_cloudfront_cache_policy.website_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers_policy.id

  }


  aliases = [var.domain_name]


  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }

  tags = {
    Name = "TheCloudResumeChallenge"
  }
}

resource "aws_cloudfront_response_headers_policy" "security_headers_policy" {
  name = "security-headers-policy"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["Content-Type"]
    }

    access_control_allow_methods {
      items = ["GET", "OPTIONS", "POST"]
    }

    access_control_allow_origins {
      items = [var.domain_name]
    }

    origin_override = true
  }

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; connect-src 'self' https://api.lauradiazcloudengineer.com; img-src 'self' data:;"
      override                = true
    }
  }
}


resource "aws_cloudfront_cache_policy" "website_cache" {
  name        = "resume-website-cache-policy"
  comment     = "Cache policy for my cloud resume challenge website"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}