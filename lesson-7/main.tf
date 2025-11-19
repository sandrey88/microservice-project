# ========================================
# AWS Free Tier Configuration
# ========================================
# Instance type: t3.micro (Free Tier eligible)
# Для production змініть на t3.medium або t3.large

provider "aws" {
  region = "eu-north-1"
}

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "terraform-state-andrii-lesson7"
  table_name  = "terraform-locks-lesson7"
}

# Підключаємо модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  vpc_name           = "lesson-7-vpc"
}

# Підключаємо модуль ECR
module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-django-app"
  scan_on_push = true
}

# Підключаємо модуль EKS
module "eks" {
  source        = "./modules/eks"
  cluster_name  = "lesson-7-eks-cluster"
  subnet_ids    = module.vpc.public_subnets
  instance_type = "t3.micro"
  desired_size  = 2
  max_size      = 3
  min_size      = 1
}
