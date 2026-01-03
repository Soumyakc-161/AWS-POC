terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# SOURCE ACCOUNT (122610480432)
provider "aws" {
  alias   = "source"
  region  = "ap-south-1"
  profile = "source"
}

# DESTINATION ACCOUNT (275092003768)
provider "aws" {
  alias   = "destination"
  region  = "ap-south-1"
  profile = "destination"
}
