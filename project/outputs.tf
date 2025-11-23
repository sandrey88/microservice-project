# ========================================
# S3 Backend Outputs
# ========================================
output "s3_bucket_name" {
  description = "Назва S3 бакета для Terraform state"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Назва DynamoDB таблиці для state locking"
  value       = module.s3_backend.dynamodb_table_name
}

# ========================================
# VPC Outputs
# ========================================
output "vpc_id" {
  description = "ID створеного VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Список ID публічних підмереж"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Список ID приватних підмереж"
  value       = module.vpc.private_subnets
}

# ========================================
# ECR Outputs
# ========================================
output "ecr_repository_url" {
  description = "URL ECR репозиторію"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN ECR репозиторію"
  value       = module.ecr.repository_arn
}

# ========================================
# EKS Outputs
# ========================================
output "eks_cluster_name" {
  description = "Назва EKS кластера"
  value       = module.eks.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint EKS кластера"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "ARN OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

# ========================================
# Jenkins Outputs
# ========================================
output "jenkins_namespace" {
  description = "Namespace де встановлено Jenkins"
  value       = module.jenkins.jenkins_namespace
}

output "jenkins_service_account" {
  description = "Service Account для Jenkins"
  value       = module.jenkins.jenkins_service_account
}

output "jenkins_url_command" {
  description = "Команда для отримання Jenkins URL"
  value       = "kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

# ========================================
# Argo CD Outputs
# ========================================
output "argocd_namespace" {
  description = "Namespace де встановлено Argo CD"
  value       = module.argo_cd.argo_cd_namespace
}

output "argocd_admin_password_command" {
  description = "Команда для отримання Argo CD admin password"
  value       = module.argo_cd.admin_password_command
}

output "argocd_url_command" {
  description = "Команда для отримання Argo CD URL"
  value       = "kubectl get svc -n argocd argo-cd-argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}
