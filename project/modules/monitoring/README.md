# Monitoring Module - Prometheus + Grafana

Модуль для розгортання повноцінного моніторингу Kubernetes кластера з використанням Prometheus та Grafana через Helm charts.

## 🎯 Можливості

- ✅ **Prometheus** - збір та зберігання метрик
- ✅ **Grafana** - візуалізація метрик з pre-installed dashboards
- ✅ **Node Exporter** - метрики з Kubernetes нод
- ✅ **Kube State Metrics** - метрики Kubernetes об'єктів
- ✅ **Alertmanager** - управління алертами
- ✅ **Persistent Storage** - збереження даних через EBS volumes
- ✅ **Resource Limits** - оптимізовано для t3.small instances

## 📋 Вимоги

- Terraform >= 1.0
- Kubernetes cluster (EKS)
- Helm provider >= 2.0
- EBS CSI Driver встановлено в кластері
- StorageClass `ebs-sc` (gp3) доступний

## 🚀 Використання

### Базовий приклад

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name            = "my-eks-cluster"
  namespace               = "monitoring"
  grafana_admin_password  = "SecurePassword123!"

  # Опціонально
  prometheus_retention    = "15d"
  prometheus_storage_size = "8Gi"
  grafana_storage_size    = "5Gi"

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### З кастомними налаштуваннями

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name            = "my-eks-cluster"
  namespace               = "monitoring"
  grafana_admin_password  = var.grafana_password

  # Prometheus
  prometheus_chart_version = "25.8.0"
  prometheus_retention     = "30d"
  prometheus_storage_size  = "20Gi"

  # Grafana
  grafana_chart_version = "7.0.8"
  grafana_storage_size  = "10Gi"

  # Exporters
  enable_node_exporter       = true
  enable_kube_state_metrics  = true

  tags = {
    Environment = "production"
    Project     = "monitoring"
  }
}
```

## 📊 Grafana Dashboards

Grafana налаштовано з Prometheus Data Source автоматично.

**Рекомендовані dashboards для імпорту:**

| Dashboard              | ID   | Опис                     |
| ---------------------- | ---- | ------------------------ |
| **Kubernetes Cluster** | 7249 | Загальний огляд кластера |
| **Kubernetes Pods**    | 6417 | Метрики подів            |
| **Node Exporter Full** | 1860 | Детальні метрики нод     |

**Імпорт через UI:** Dashboards → Import → введіть ID → Load → Select Prometheus → Import

## 🔧 Змінні

| Змінна                      | Тип         | За замовчуванням | Опис                              |
| --------------------------- | ----------- | ---------------- | --------------------------------- |
| `cluster_name`              | string      | -                | Назва EKS кластера (обов'язково)  |
| `namespace`                 | string      | `"monitoring"`   | Kubernetes namespace              |
| `prometheus_chart_version`  | string      | `"25.8.0"`       | Версія Helm chart Prometheus      |
| `grafana_chart_version`     | string      | `"7.0.8"`        | Версія Helm chart Grafana         |
| `grafana_admin_password`    | string      | `"admin123"`     | Пароль адміна Grafana (sensitive) |
| `prometheus_retention`      | string      | `"15d"`          | Час зберігання метрик             |
| `prometheus_storage_size`   | string      | `"8Gi"`          | Розмір storage для Prometheus     |
| `grafana_storage_size`      | string      | `"5Gi"`          | Розмір storage для Grafana        |
| `enable_node_exporter`      | bool        | `true`           | Увімкнути Node Exporter           |
| `enable_kube_state_metrics` | bool        | `true`           | Увімкнути Kube State Metrics      |
| `tags`                      | map(string) | `{}`             | Теги для ресурсів                 |

## 📤 Outputs

| Output                            | Опис                             |
| --------------------------------- | -------------------------------- |
| `namespace`                       | Kubernetes namespace моніторингу |
| `prometheus_url`                  | Internal URL Prometheus          |
| `prometheus_port_forward_command` | Команда для port-forward         |
| `grafana_url`                     | Internal URL Grafana             |
| `grafana_port_forward_command`    | Команда для port-forward         |
| `grafana_admin_user`              | Username адміна Grafana          |
| `grafana_admin_password`          | Пароль адміна (sensitive)        |
| `monitoring_info`                 | Повна інформація про моніторинг  |
| `grafana_dashboards`              | Список встановлених dashboards   |

## 🔍 Доступ до сервісів

### Prometheus

```bash
# Port-forward
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Відкрийте в браузері
http://localhost:9090
```

### Grafana

```bash
# Port-forward
kubectl port-forward -n monitoring svc/grafana 3000:80

# Відкрийте в браузері
http://localhost:3000

# Логін
Username: admin
Password: <ваш grafana_admin_password>
```

### Отримати пароль Grafana

```bash
# Через Terraform output
terraform output -raw grafana_admin_password

# Або через kubectl
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

## 📈 Перевірка метрик

### Prometheus Targets

1. Відкрийте Prometheus UI: `http://localhost:9090`
2. Перейдіть в **Status → Targets**
3. Перевірте що targets в стані `UP`:
   - ✅ `kubernetes-apiservers`
   - ✅ `kubernetes-nodes`
   - ✅ `kube-state-metrics`
   - ✅ `node-exporter`

### Prometheus Queries для тестування

```promql
# Pods по namespace
count(kube_pod_info) by (namespace)

# Running pods
sum(kube_pod_status_phase{phase="Running"})

# API Server requests
rate(apiserver_request_total[5m])

# Memory usage по namespace
sum(container_memory_usage_bytes{namespace!=""}) by (namespace)
```

### Grafana Dashboards

1. Відкрийте Grafana UI: `http://localhost:3000`
2. Логін: `admin` / `<ваш пароль>`
3. **Dashboards → Import**
4. Введіть Dashboard ID (7249, 6417, або 1860)
5. **Load → Select Prometheus → Import**

## 🔒 Security Best Practices

1. **Змініть пароль Grafana**:

   ```hcl
   grafana_admin_password = var.grafana_password  # Використовуйте змінну
   ```

2. **Використовуйте Secrets Manager** (для production):

   ```hcl
   data "aws_secretsmanager_secret_version" "grafana_password" {
     secret_id = "grafana-admin-password"
   }

   grafana_admin_password = data.aws_secretsmanager_secret_version.grafana_password.secret_string
   ```

3. **Обмежте доступ через Network Policies**:

   - Дозвольте доступ тільки з певних namespaces
   - Використовуйте Ingress з authentication

4. **Увімкніть HTTPS** (для production):
   - Налаштуйте Ingress з TLS
   - Використовуйте cert-manager для автоматичних сертифікатів

## 💰 Вартість

### Storage (EBS gp3)

- **Prometheus**: 8 GB × $0.08/GB-місяць = ~$0.64/міс
- **Grafana**: 5 GB × $0.08/GB-місяць = ~$0.40/міс
- **Alertmanager**: 2 GB × $0.08/GB-місяць = ~$0.16/міс

**Загалом storage**: ~$1.20/міс

### Compute

Ресурси працюють на існуючих EKS nodes (t3.small), тому додаткових витрат на compute немає.

**Загальна вартість моніторингу**: ~$1-2/міс

## 🧪 Тестування

### 1. Перевірка Helm releases

```bash
helm list -n monitoring
```

Очікуваний результат:

```
NAME        NAMESPACE   STATUS      CHART
prometheus  monitoring  deployed    prometheus-25.8.0
grafana     monitoring  deployed    grafana-7.0.8
```

### 2. Перевірка pods

```bash
kubectl get pods -n monitoring
```

Всі поди мають бути в стані `Running`.

### 3. Перевірка PVC

```bash
kubectl get pvc -n monitoring
```

Всі PVC мають бути в стані `Bound`.

### 4. Тестування метрик

```bash
# Port-forward до Prometheus
kubectl port-forward -n monitoring svc/prometheus-server 9090:80 &

# Запит метрик
curl http://localhost:9090/api/v1/query?query=up

# Має повернути список всіх targets
```

## 🐛 Troubleshooting

### Prometheus не збирає метрики

```bash
# Перевірте logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Перевірте targets
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Відкрийте http://localhost:9090/targets
```

### Grafana не підключається до Prometheus

```bash
# Перевірте datasource
kubectl exec -n monitoring -it deployment/grafana -- \
  curl http://prometheus-server.monitoring.svc.cluster.local

# Має повернути HTML сторінку Prometheus
```

### PVC в стані Pending

```bash
# Перевірте StorageClass
kubectl get sc

# Перевірте EBS CSI Driver
kubectl get pods -n kube-system -l app=ebs-csi-controller

# Перевірте events
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

### Поди не запускаються (OOMKilled)

Якщо поди падають через нестачу пам'яті на t3.small:

```hcl
# Зменшіть resource limits
module "monitoring" {
  # ... інші параметри

  # В monitoring.tf відредагуйте:
  # server.resources.limits.memory = "768Mi"  # замість 1Gi
  # grafana.resources.limits.memory = "384Mi" # замість 512Mi
}
```

## 📚 Додаткові ресурси

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus)
- [Grafana Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Kubernetes Monitoring Guide](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)

## 🎓 Приклади запитів Prometheus

### Pod Metrics (kube-state-metrics)

```promql
# Кількість pods по namespace
count(kube_pod_info) by (namespace)

# Running pods
sum(kube_pod_status_phase{phase="Running"})

# Failed pods
sum(kube_pod_status_phase{phase="Failed"})

# Pods по node
count(kube_pod_info) by (node)
```

### CPU Usage

```promql
# CPU usage по подах
sum(rate(container_cpu_usage_seconds_total{namespace!=""}[5m])) by (pod, namespace)

# CPU usage по нодах
sum(rate(container_cpu_usage_seconds_total[5m])) by (node)
```

### Memory Usage

```promql
# Memory usage по подах
sum(container_memory_usage_bytes{namespace!=""}) by (pod, namespace)

# Memory usage по namespace
sum(container_memory_usage_bytes{namespace!=""}) by (namespace)

# Memory usage по нодах (Node Exporter)
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
```

### API Server Metrics

```promql
# API requests rate
rate(apiserver_request_total[5m])

# API requests by verb
sum(rate(apiserver_request_total[5m])) by (verb)
```
