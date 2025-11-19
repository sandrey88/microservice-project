output "repository_url" {
  description = "URL репозиторію ECR"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_arn" {
  description = "ARN репозиторію ECR"
  value       = aws_ecr_repository.main.arn
}

output "repository_name" {
  description = "Назва репозиторію ECR"
  value       = aws_ecr_repository.main.name
}
