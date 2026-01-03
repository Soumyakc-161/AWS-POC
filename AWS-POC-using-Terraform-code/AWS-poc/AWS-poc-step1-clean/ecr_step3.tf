############################################
# ECR Repository for Inventory Splitter
############################################
resource "aws_ecr_repository" "ecr_inventory_splitter" {
  provider = aws.source

  name = "ecr-inventory-splitter"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    Name        = "ecr-inventory-splitter"
    Environment = var.env
    Account     = "source"
  }
}


#ECR lifecycle policy to retain last 10 images
resource "aws_ecr_lifecycle_policy" "ecr_inventory_splitter" {
  provider   = aws.source
  repository = aws_ecr_repository.ecr_inventory_splitter.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
