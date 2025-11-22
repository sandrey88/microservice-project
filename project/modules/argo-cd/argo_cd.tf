# Helm Release для Argo CD
resource "helm_release" "argo_cd" {
  name             = var.name
  namespace        = var.namespace
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]
}

# Helm Release для Argo CD Applications
resource "helm_release" "argo_apps" {
  name      = "${var.name}-apps"
  chart     = "${path.module}/charts"
  namespace = var.namespace
  create_namespace = false

  set {
    name  = "applications[0].name"
    value = var.app_name
  }

  set {
    name  = "applications[0].namespace"
    value = var.app_namespace
  }

  set {
    name  = "applications[0].source.repoURL"
    value = var.helm_repo_url
  }

  set {
    name  = "applications[0].source.path"
    value = var.helm_chart_path
  }

  set {
    name  = "repositories[0].url"
    value = var.helm_repo_url
  }

  set {
    name  = "repositories[0].username"
    value = var.github_username
  }

  set {
    name  = "repositories[0].password"
    value = var.github_token
  }

  depends_on = [helm_release.argo_cd]
}
