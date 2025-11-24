# ========================================
# AWS Free Tier Configuration
# ========================================
# Instance type: t3.small
# Для production змініть на t3.medium або t3.large

provider "aws" {
  region = "eu-north-1"
}

# ========================================
# Data Sources для EKS
# ========================================
data "aws_eks_cluster" "eks" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

# ========================================
# Helm Provider Configuration
# ========================================
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

# ========================================
# Kubernetes Provider Configuration
# ========================================
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

# ========================================
# S3 Backend Module
# ========================================
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "terraform-state-andrii-project"
  table_name  = "terraform-locks-project"
}

# ========================================
# VPC Module
# ========================================
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "project-vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  availability_zones = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

# ========================================
# ECR Module
# ========================================
module "ecr" {
  source   = "./modules/ecr"
  ecr_name = "project-django-app"
}

# ========================================
# EKS Module (t3.small x3 - AWS Free Tier limitation)
# ========================================
module "eks" {
  source = "./modules/eks"

  cluster_name  = "project-eks-cluster"
  subnet_ids    = concat(module.vpc.public_subnets, module.vpc.private_subnets)
  instance_type = "t3.small"
  desired_size  = 3
  max_size      = 3
  min_size      = 2
}

# ========================================
# Jenkins Module
# ========================================
module "jenkins" {
  source = "./modules/jenkins"

  cluster_name      = module.eks.eks_cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  github_username = var.github_username
  github_token    = var.github_token
  github_repo_url = var.github_repo_url

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]
}

# ========================================
# Argo CD Module
# ========================================
module "argo_cd" {
  source = "./modules/argo-cd"

  namespace       = "argocd"
  chart_version   = "5.46.4"
  helm_repo_url   = var.helm_repo_url
  helm_chart_path = "charts/django-app"

  github_username = var.github_username
  github_token    = var.github_token

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.eks]
}

# ========================================
# RDS Module
# ========================================
module "rds" {
  source = "./modules/rds"

  name       = "project-django-db"
  use_aurora = false # Змініть на true для Aurora

  # --- RDS-only параметри ---
  engine                     = "postgres"
  engine_version             = "16.4"
  parameter_group_family_rds = "postgres16"

  # --- Aurora-only параметри (якщо use_aurora = true) ---
  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "15.3"
  parameter_group_family_aurora = "aurora-postgresql15"
  aurora_replica_count          = 1

  # --- Спільні параметри ---
  instance_class    = "db.t3.small" # Free Tier compatible
  allocated_storage = 20
  db_name           = "djangodb"
  username          = "postgres"
  password          = var.db_password # Додамо змінну

  subnet_private_ids  = module.vpc.private_subnets
  subnet_public_ids   = module.vpc.public_subnets
  publicly_accessible = false # Для production = false
  vpc_id              = module.vpc.vpc_id

  multi_az                = false # Для Free Tier = false
  backup_retention_period = 7
  skip_final_snapshot     = true # Для dev/test = true

  parameters = {
    max_connections            = "100"
    log_min_duration_statement = "1000"
    shared_buffers             = "256MB"
  }

  tags = {
    Environment = "dev"
    Project     = "django-ci-cd"
    ManagedBy   = "Terraform"
  }

  depends_on = [module.vpc]
}
