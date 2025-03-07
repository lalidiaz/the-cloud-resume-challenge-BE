variable "bucket_name" {
  description = "Name of the S3 bucket for the cloud resume challenge"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the website"
  type        = string
}

variable "email" {
  description = "My personal email"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "table_name" {
  description = "Table name in Dynamodb"
  type        = string
}

