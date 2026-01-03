#Enable S3 Inventory on source bucket
resource "aws_s3_bucket_inventory" "source_policy_inventory" {
  provider = aws.source

  bucket = aws_s3_bucket.source_policy_history.id
  name   = "s3-inventory"

  included_object_versions = "Current"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      bucket_arn = aws_s3_bucket.destination_analytics_raw.arn
      format     = "CSV"
    }
  }

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag"
  ]
}

#this is policy not IAM role 
# Bucket policy on destination bucket to allow S3 Inventory from source account
resource "aws_s3_bucket_policy" "allow_source_inventory" {
  provider = aws.destination

  bucket = aws_s3_bucket.destination_analytics_raw.id

  policy = jsonencode({
    Version = "2012-10-17"
    # Allow inventory files to be written by S3 service from source account
    Statement = [
      {
        Sid    = "AllowS3InventoryFromSourceAccount"
        Effect = "Allow"

        Principal = {
          Service = "s3.amazonaws.com"
        }

        Action = "s3:PutObject"


        Resource = "${aws_s3_bucket.destination_analytics_raw.arn}/*"

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "122610480432"
          }
        }
      }
    ]
  })
}