# Source bucket (Account: source profile)
resource "aws_s3_bucket" "source_policy_history" {
  provider = aws.source

  bucket = var.source_bucket_name

  tags = {
    Name        = "policy-history"
    Environment = var.env
    Account     = "source"
  }
}

# Destination bucket (Account: destination profile)
resource "aws_s3_bucket" "destination_analytics_raw" {
  provider = aws.destination

  bucket = var.destination_bucket_name

  tags = {
    Name        = "analytics-raw"
    Environment = var.env
    Account     = "destination"
  }
}
