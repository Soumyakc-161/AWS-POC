variable "env" {
  description = "Environment name (dev / test / prod)"
  type        = string
}

variable "source_bucket_name" {
  description = "Source S3 bucket (policy history)"
  type        = string
}

variable "destination_bucket_name" {
  description = "Destination S3 bucket (analytics raw)"
  type        = string
}
# line number 1 to 14 to create the source and destination bucket variables
#--------------------------------------------------------------------
#--------------------------------------------------------------------

variable "vpc_id_source" {
  description = "VPC ID for AWS Batch compute environment (source account)"
  type        = string
}



variable "subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}



variable "ecr_image" {
  type = string
}
