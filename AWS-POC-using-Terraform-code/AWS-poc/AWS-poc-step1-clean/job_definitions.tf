############################################################
# JOB DEFINITIONS FILE
# TWO BEHAVIORS:
#   Job-1 → inventory-splitter
#   Job-2 → chunk-processor
############################################################


# ==========================================================
#  JOB-1 DEFINITION
# NAME: inventory-splitter
# PURPOSE:
#   - Read S3 Inventory manifest
#   - Split object list into chunk CSV files
#   - Write chunks to: inventory-chunks/
# ==========================================================
resource "aws_batch_job_definition" "inventory_splitter" {
  provider = aws.source

  #  JOB-1 NAME (used in submit-job)
  name = "inventory-splitter"
  type = "container"

  
  platform_capabilities = ["FARGATE"]#  JOB-1 runs on Fargate

  container_properties = jsonencode({

    #  SHARED (JOB-1 + JOB-2)
    # Same Docker image, behavior decided by command
    #image = var.ecr_image
    image = "${aws_ecr_repository.ecr_inventory_splitter.repository_url}:latest"

    #  JOB-1 SPECIFIC
    # Runs inventory splitter script
    command = ["python", "inventory_splitter.py"]

    #  JOB-1 COMPUTE REQUIREMENTS
    resourceRequirements = [
      { type = "VCPU",   value = "1" },
      { type = "MEMORY", value = "2048" }
    ]

    #  SHARED (JOB-1 + JOB-2)
    # Runtime IAM role for S3 access
    jobRoleArn = aws_iam_role.batch_job_role.arn

    #  SHARED (JOB-1 + JOB-2)
    # Execution role (ECR pull + logs)
    executionRoleArn = aws_iam_role.batch_execution_role.arn

    #  SHARED
    networkConfiguration = {
      assignPublicIp = "ENABLED"
    }

    #  JOB-1 ENV VARIABLES
    # Used ONLY by inventory_splitter.py
    environment = [
      # Source bucket containing inventory
      { name = "INVENTORY_BUCKET", value = var.source_bucket_name },

      # Exact inventory manifest file
      { name = "MANIFEST_KEY", value = "soumyakc-source-mum-999/s3-inventory/2025-12-25T01-00Z/manifest.json" },

      # Destination bucket for chunks
      { name = "destination_bucket_name", value = var.destination_bucket_name },

      # Number of records per chunk file
      { name = "CHUNK_SIZE", value = "10000" }
    ]
  })
}






# ==========================================================
#  JOB-2 DEFINITION
# NAME: chunk-processor
# PURPOSE:
#   - Read chunk CSV files
#   - Process actual S3 objects
#   - Write final processed output
# ==========================================================
resource "aws_batch_job_definition" "chunk_processor" {
  provider = aws.source

  #  JOB-2 NAME (used in submit-job)
  name = "chunk-processor"

  type = "container"

  #  JOB-2 runs on Fargate
  platform_capabilities = ["FARGATE"]

  container_properties = jsonencode({

    #  SHARED (JOB-1 + JOB-2)
    # Same image, different command
    image = var.ecr_image

    #  JOB-2 SPECIFIC
    # Runs chunk processor script
    command = ["python", "chunk_processor.py"]

    #  JOB-2 COMPUTE REQUIREMENTS
    resourceRequirements = [
      { type = "VCPU",   value = "1" },
      { type = "MEMORY", value = "2048" }
    ]

    #  SHARED (JOB-1 + JOB-2)
    jobRoleArn = aws_iam_role.batch_job_role.arn

    #  SHARED (JOB-1 + JOB-2)
    executionRoleArn = aws_iam_role.batch_execution_role.arn

    #  SHARED
    networkConfiguration = {
      assignPublicIp = "ENABLED"
    }

    #  JOB-2 ENV VARIABLES
    # Used ONLY by chunk_processor.py
    environment = [
      # Source bucket (actual data objects)
      { name = "source_bucket_name", value = var.source_bucket_name },

      # Destination bucket for processed output
      { name = "destination_bucket_name", value = var.destination_bucket_name },

      # Partition/date to pick correct chunk folder
      { name = "RUN_DATE", value = "2025-12-27" }
    ]
  })
}
