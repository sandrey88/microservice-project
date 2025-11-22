output "jenkins_release_name" {
  description = "Назва Helm release для Jenkins"
  value       = helm_release.jenkins.name
}

output "jenkins_namespace" {
  description = "Namespace де встановлено Jenkins"
  value       = helm_release.jenkins.namespace
}

output "jenkins_service_account" {
  description = "Service Account для Jenkins"
  value       = kubernetes_service_account.jenkins_sa.metadata[0].name
}

output "jenkins_iam_role_arn" {
  description = "IAM Role ARN для Jenkins Kaniko"
  value       = aws_iam_role.jenkins_kaniko_role.arn
}
