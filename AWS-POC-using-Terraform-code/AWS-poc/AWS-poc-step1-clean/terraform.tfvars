env = "dev"

source_bucket_name      = "soumyakc-source-mum-999"
destination_bucket_name = "soumyakc-dest-mum-999"

#--------------------------------------------------------------------
#--------------------------------------------------------------------
ecr_image = "122610480432.dkr.ecr.ap-south-1.amazonaws.com/ecr-inventory-splitter:latest"

vpc_id_source = "vpc-05aa0def4cfbc467d"

subnets = [
  "subnet-05bf44109e71818f7",
  "subnet-0b931ba1088037e74"
]


security_groups = [
  "sg-0a6f44fb30336ada9"
]