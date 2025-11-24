variable "github_username" {
  description = "GitHub username для доступу до репозиторіїв"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_repo_url" {
  description = "URL GitHub репозиторію з кодом Django застосунку (для Jenkins)"
  type        = string
}

variable "helm_repo_url" {
  description = "URL GitHub репозиторію з Helm charts (для Argo CD)"
  type        = string
}

variable "db_password" {
  description = "Master password для RDS/Aurora database"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!" # Змініть на безпечний пароль
}
