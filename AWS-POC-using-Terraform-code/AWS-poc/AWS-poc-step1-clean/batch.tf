#COMPUTE + QUEUE + JOB DEFINITIONS
# ############################################

# Compute Environment (Fargate – simplest)
resource "aws_batch_compute_environment" "ce" {
  provider = aws.source

  compute_environment_name = "batch-Compute_environment"
  type                     = "MANAGED"

  compute_resources {
    type               = "FARGATE"
    max_vcpus          = 16
    subnets            = var.subnets
    security_group_ids = var.security_groups
    
  }

  service_role = aws_iam_role.batch_service_role.arn
}



# Job Queue
resource "aws_batch_job_queue" "queue" {
  provider = aws.source
  name     = "batch-queue"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order = 1
    compute_environment = aws_batch_compute_environment.ce.arn
  }

  }
