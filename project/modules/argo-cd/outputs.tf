output "argo_cd_server_service" {
  description = "Argo CD server service"
  value       = "argo-cd-server.${var.namespace}.svc.cluster.local"
}

output "admin_password_command" {
  description = "Команда для отримання initial admin password"
  value       = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argo_cd_namespace" {
  description = "Namespace де встановлено Argo CD"
  value       = helm_release.argo_cd.namespace
}
