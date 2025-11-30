# ========================================
# Monitoring Module - Prometheus + Grafana
# ========================================

# Створення namespace для моніторингу
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# ========================================
# Prometheus - Збір метрик
# ========================================

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = var.prometheus_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/prometheus-values.yaml", {
      retention_period          = var.prometheus_retention
      storage_size              = var.prometheus_storage_size
      enable_node_exporter      = var.enable_node_exporter
      enable_kube_state_metrics = var.enable_kube_state_metrics
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# ========================================
# Grafana - Візуалізація метрик
# ========================================

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.grafana_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    templatefile("${path.module}/grafana-values.yaml", {
      admin_password = var.grafana_admin_password
      storage_size   = var.grafana_storage_size
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.prometheus
  ]
}
