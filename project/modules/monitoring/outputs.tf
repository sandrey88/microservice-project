# ========================================
# Monitoring Module Outputs
# ========================================

# Namespace
output "namespace" {
  description = "Kubernetes namespace для моніторингу"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

# Prometheus
output "prometheus_release_name" {
  description = "Назва Helm release для Prometheus"
  value       = helm_release.prometheus.name
}

output "prometheus_service_name" {
  description = "Назва Kubernetes service для Prometheus"
  value       = "prometheus-server"
}

output "prometheus_service_port" {
  description = "Порт Prometheus service"
  value       = 80
}

output "prometheus_url" {
  description = "Internal URL для доступу до Prometheus"
  value       = "http://prometheus-server.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
}

output "prometheus_port_forward_command" {
  description = "Команда для port-forward до Prometheus"
  value       = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/prometheus-server 9090:80"
}

# Grafana
output "grafana_release_name" {
  description = "Назва Helm release для Grafana"
  value       = helm_release.grafana.name
}

output "grafana_service_name" {
  description = "Назва Kubernetes service для Grafana"
  value       = "grafana"
}

output "grafana_service_port" {
  description = "Порт Grafana service"
  value       = 80
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = "admin"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "grafana_url" {
  description = "Internal URL для доступу до Grafana"
  value       = "http://grafana.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
}

output "grafana_port_forward_command" {
  description = "Команда для port-forward до Grafana"
  value       = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/grafana 3000:80"
}

# Connection info
output "monitoring_info" {
  description = "Інформація про моніторинг"
  value = {
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    prometheus = {
      service      = "prometheus-server"
      port         = 80
      url          = "http://prometheus-server.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
      port_forward = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/prometheus-server 9090:80"
    }
    grafana = {
      service      = "grafana"
      port         = 80
      url          = "http://grafana.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
      port_forward = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/grafana 3000:80"
      admin_user   = "admin"
    }
  }
}

# Dashboards
output "grafana_dashboards" {
  description = "Список pre-installed Grafana dashboards"
  value = {
    "Kubernetes Cluster" = "Dashboard ID: 7249"
    "Kubernetes Pods"    = "Dashboard ID: 6417"
    "Node Exporter"      = "Dashboard ID: 1860"
    "K8s Deployment"     = "Dashboard ID: 8588"
  }
}
