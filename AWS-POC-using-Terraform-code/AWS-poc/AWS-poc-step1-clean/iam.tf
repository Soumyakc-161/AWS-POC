############################################
# JOB 1: inventory-splitter
# JOB 2: chunk-processor
# NOTE: BOTH jobs run as AWS Batch ECS tasks
############################################


# =========================================================
#  SHARED — JOB ROLE USED BY BOTH JOB 1 & JOB 2
# This role is assumed INSIDE the container
#IAM roles used in STEP 3 batch_job_role
# =========================================================
resource "aws_iam_role" "batch_job_role" {
  provider = aws.source
  name     = "batch_job_role"

  # Used by BOTH jobs (inventory-splitter + chunk-processor)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach S3 policy (used by BOTH jobs)
resource "aws_iam_role_policy_attachment" "job_role_attach" {
  provider   = aws.source
  role       = aws_iam_role.batch_job_role.name
  policy_arn = aws_iam_policy.batch_s3_policy.arn
}
#

# =========================================================
#  SHARED POLICY — USED BY BOTH JOBS
# Contains permissions split internally by job behavior
# =========================================================
resource "aws_iam_policy" "batch_s3_policy" {
  provider = aws.source
  name     = "batch-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

       # ===================================================
      #  JOB 1 + JOB 2
      # LIST DESTINATION BUCKET
      # ===================================================
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::soumyakc-dest-mum-999"
      },

      # ===================================================
      #  JOB 1 + JOB 2
      # READ SOURCE BUCKET (inventory + actual objects)
        #  JOB 1 + JOB 2
      # WRITE TO DESTINATION BUCKET
      # - Job 1: writes inventory-chunks/*
      # - Job 2: writes processed output files
      # ===================================================
      /*{
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "arn:aws:s3:::soumyakc-source-mum-999/*"
        ]
      },*/
      # READ source inventory + chunk files
        {
          Effect = "Allow"
          Action = ["s3:GetObject"]
          Resource = [
            "arn:aws:s3:::soumyakc-source-mum-999/*",
            "arn:aws:s3:::soumyakc-dest-mum-999/inventory-chunks/*"
          ]
        },

        # WRITE chunks + parquet output
        {
          Effect = "Allow"
          Action = ["s3:PutObject"]
          Resource = [
            "arn:aws:s3:::soumyakc-dest-mum-999/inventory-chunks/*",
            "arn:aws:s3:::soumyakc-dest-mum-999/processed/*",
            "arn:aws:s3:::soumyakc-dest-mum-999/parquet/*"
          ]
        },

           
      # ===================================================
      #  JOB 1 + JOB 2
      # CLOUDWATCH LOGS
      # ===================================================
      {
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to job role (BOTH jobs)
resource "aws_iam_role_policy_attachment" "batch_job_role_attach" {
  provider   = aws.source
  role       = aws_iam_role.batch_job_role.name
  policy_arn = aws_iam_policy.batch_s3_policy.arn
}


#------------------Till this for Job 1 Inventory splitter ----------------------------


# =========================================================
#  SHARED — EXECUTION ROLE (ECR + LOGS)
# Used by BOTH jobs to:
# - Pull Docker image from ECR
# - Push logs to CloudWatch
# =========================================================
resource "aws_iam_role" "batch_execution_role" {
  provider = aws.source
  name     = "batch_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "batch_execution_role_attach" {
  provider   = aws.source
  role       = aws_iam_role.batch_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# =========================================================
# DESTINATION BUCKET POLICY (Analytics Account)
# This is where JOB 1 writes chunks
# and JOB 2 reads chunks + writes output
# =========================================================
#resource "aws_s3_bucket_policy" "allow_batch_read_inventory_and_chunks" {
resource "aws_s3_bucket_policy" "destination_bucket_policy" {
  provider = aws.destination
  bucket   = aws_s3_bucket.destination_analytics_raw.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # ===================================================
      # SYSTEM — S3 INVENTORY SERVICE WRITES FILES TO DESTINATION BUCKET this is for step 2 
      # ===================================================
      /*{
        Sid    = "AllowS3InventoryWrite"
        Effect = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = ["s3:PutObject"]
        Resource  = "${aws_s3_bucket.destination_analytics_raw.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "122610480432"
          }
        }
      }*/

      # ===================================================
      #  JOB 1 + JOB 2
      # Allow bucket listing
      # ===================================================
      {
        Sid       = "AllowBatchListBucket"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::122610480432:role/batch_job_role" }
        Action    = "s3:ListBucket"
        Resource  = "${aws_s3_bucket.destination_analytics_raw.arn}"
      },

      # ===================================================
      #  JOB 1 ONLY — READ INVENTORY FILES
      # ===================================================
      {
        Sid       = "AllowBatchReadWriteObjects"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::122610480432:role/batch_job_role" }
        #Action    = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
        Action    = ["s3:GetObject", "s3:PutObject"]
        Resource  = "${aws_s3_bucket.destination_analytics_raw.arn}/soumyakc-source-mum-999/s3-inventory/*"
      },
      {
        Sid    = "AllowBatchReadChunks"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::122610480432:role/batch_job_role"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.destination_analytics_raw.arn}/inventory-chunks/*"
      },

      {
        Sid    = "AllowBatchWriteParquet"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::122610480432:role/batch_job_role"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.destination_analytics_raw.arn}/parquet/*"
      },
      {
        Sid    = "AllowBatchWriteProcessedParquet",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::122610480432:role/batch_job_role"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.destination_analytics_raw.arn}/processed/*"
      },
      {
        Sid    = "AllowBatchReadChunksHeadAndGet",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::122610480432:role/batch_job_role"
        },
        Action = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.destination_analytics_raw.arn}/inventory-chunks/*"
      }



      # ===================================================
      #  JOB 1 ONLY — WRITE CHUNK FILES
      # ===================================================
      /*{
        Sid       = "AllowBatchWriteChunks"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::122610480432:role/batch_job_role" }
        Action    = ["s3:PutObject"]
        Resource  = "${aws_s3_bucket.destination_analytics_raw.arn}/inventory-chunks/*"
      }*/
      

      # ===================================================
      #  JOB 2 ONLY — READ CHUNK FILES
      # ===================================================
      /*{
        Sid       = "AllowBatchReadChunkFiles"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::122610480432:role/batch_job_role" }
        Action    = ["s3:GetObject"]
        Resource  = "arn:aws:s3:::soumyakc-dest-mum-999/inventory-chunks/*"
      },
      #  JOB 2 ONLY  Allow Batch Job Role to READ chunk files
      
      #JOB 2    Allow Batch Job Role to WRITE parquet output
      */


      
	  
    ]
  })
}

# =========================================================
#  JOB 2 ONLY (mainly)
# Read chunks + write processed output
# =========================================================



# =========================================================
#  SHARED — AWS BATCH SERVICE ROLE
# Used by AWS Batch itself (NOT job logic)
# =========================================================
resource "aws_iam_role" "batch_service_role" {
  provider = aws.source
  name     = "aws-batch-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "batch.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service_role_attach" {
  provider   = aws.source
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
  
}


#job queue
# resource "aws_batch_job_queue" "queue" {
#   provider = aws.source
#   name     = "batch-queue"
#   state    = "ENABLED"
#   priority = 1
#
#   compute_environment_order {
#     order = 1
#     compute_environment = module.batch_wk_compute_environment.compute_environments.a_fargate.arn
#   }
# }







