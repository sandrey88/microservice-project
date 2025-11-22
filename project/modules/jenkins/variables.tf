variable "cluster_name" {
  description = "Назва Kubernetes кластера"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN OIDC Provider для IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL OIDC Provider"
  type        = string
}

variable "github_username" {
  description = "GitHub username для доступу до репозиторію"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_repo_url" {
  description = "URL GitHub репозиторію з кодом"
  type        = string
}
