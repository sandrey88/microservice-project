variable "name" {
  description = "Назва Helm-релізу"
  type        = string
  default     = "argo-cd"
}

variable "namespace" {
  description = "K8s namespace для Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Версія Argo CD чарта"
  type        = string
  default     = "5.46.4"
}

variable "app_name" {
  description = "Назва застосунку в Argo CD"
  type        = string
  default     = "django-app"
}

variable "app_namespace" {
  description = "Namespace для застосунку"
  type        = string
  default     = "default"
}

variable "helm_repo_url" {
  description = "URL Git репозиторію з Helm charts"
  type        = string
}

variable "helm_chart_path" {
  description = "Шлях до Helm chart в репозиторії"
  type        = string
  default     = "charts/django-app"
}

variable "github_username" {
  description = "GitHub username"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}
