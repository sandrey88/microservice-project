variable "cluster_name" {
  description = "Назва EKS кластера"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace для моніторингу"
  type        = string
  default     = "monitoring"
}

variable "prometheus_chart_version" {
  description = "Версія Helm chart для Prometheus"
  type        = string
  default     = "25.8.0"
}

variable "grafana_chart_version" {
  description = "Версія Helm chart для Grafana"
  type        = string
  default     = "7.0.8"
}

variable "grafana_admin_password" {
  description = "Пароль адміністратора Grafana"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "prometheus_retention" {
  description = "Час зберігання метрик Prometheus"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Розмір storage для Prometheus"
  type        = string
  default     = "8Gi"
}

variable "grafana_storage_size" {
  description = "Розмір storage для Grafana"
  type        = string
  default     = "5Gi"
}

variable "enable_node_exporter" {
  description = "Увімкнути Node Exporter для збору метрик нод"
  type        = bool
  default     = true
}

variable "enable_kube_state_metrics" {
  description = "Увімкнути Kube State Metrics"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Теги для ресурсів"
  type        = map(string)
  default     = {}
}
