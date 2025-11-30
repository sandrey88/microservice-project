# Quick Start - CI/CD Pipeline

Швидкий старт для запуску повного CI/CD pipeline з Jenkins + Argo CD.

## ⚠️ Instance Type Configuration

Проєкт налаштовано для **AWS Free Tier** з оптимізацією:

**Важливо**: AWS Free Tier має обмеження на типи інстансів.

- **EKS Nodes**: 3× t3.small (2 vCPU, 2 GB RAM)
- **RDS Instance**: db.t3.micro (1 vCPU, 1 GB RAM) - Free Tier
- **RDS Backup**: 1 день (Free Tier максимум)
- **PostgreSQL**: версія 16.6

!!! Поточний регіон в проєкті - "eu-north-1", за потреби його можна змінити.

## Передумови

- AWS CLI налаштовано
- 2 GitHub репозиторії створено:
  - `django-app` (код)
  - `helm-charts` (charts)
- GitHub Personal Access Token

## Крок 1: Підготовка (5 хв)

```bash
# Перейдіть в директорію проєкту
cd project

# Створіть terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # заповніть ваші дані

# Оновіть ECR URL в Jenkinsfile
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
sed -i "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" Jenkinsfile

# Оновіть ECR URL в values.yaml
sed -i "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" charts/django-app/values.yaml
```

## Крок 2: Terraform Apply (15-20 хв)

```bash
terraform init
terraform apply -auto-approve

# Після завершення - міграція state
nano backend.tf  # розкоментуйте
terraform init -reconfigure
```

## Крок 3: Налаштування kubectl (1 хв)

```bash
aws eks update-kubeconfig --region eu-north-1 --name project-eks-cluster
kubectl get nodes
```

## Крок 4: Jenkins (2 хв)

```bash
# URL
kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Логін: admin / admin123
# Запустіть: seed-job -> django-ci-cd
```

## Крок 5: Argo CD (2 хв)

```bash
# URL
kubectl get svc -n argocd argo-cd-argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Логін: admin / <password>
# Sync: django-app
```

## Крок 6: Перевірка Django (1 хв)

```bash
kubectl get svc django-app-django -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
curl http://<URL>
```

## Крок 7: Моніторинг - Prometheus + Grafana (2 хв)

```bash
# Перевірка pods
kubectl get all -n monitoring

# Prometheus (port-forward)
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring &

# Grafana (port-forward)
kubectl port-forward svc/grafana 3000:80 -n monitoring &

# Отримати пароль Grafana
kubectl get secret -n monitoring grafana -o jsonpath='{.data.admin-password}' | base64 -d
# Пароль: admin123

# Відкрийте в браузері:
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000
# Login: admin / admin123
```

**Prometheus Queries для тестування:**

В Prometheus UI (http://localhost:9090):

1. **Status → Targets** - перевірити що endpoints UP:

   - kubernetes-apiservers
   - kubernetes-nodes
   - kube-state-metrics
   - node-exporter

2. **Graph → Query:**

   ```promql
   # Pods по namespace
   count(kube_pod_info) by (namespace)
   ```

3. **Graph → Query:**
   ```promql
   # Running pods
   sum(kube_pod_status_phase{phase="Running"})
   ```

**Grafana Dashboards:**

Після першого `terraform apply` Grafana вже містить попередньо налаштовані dashboards.

**Якщо потрібно додати більше:**

Імпортуйте через UI (Dashboards → Import):

- Kubernetes Cluster (ID: 7249)
- Kubernetes Pods (ID: 6417)
- Node Exporter (ID: 1860)

**Data Source:** Prometheus налаштовано автоматично при розгортанні

## Тестування CI/CD

```bash
# Зробіть зміни в django-app
cd ../django-app
echo "# Test" >> README.md
git add .
git commit -m "Test CI/CD"
git push

# Jenkins автоматично:
# 1. Збере образ
# 2. Запушить до ECR
# 3. Оновить values.yaml

# Argo CD автоматично:
# 1. Виявить зміни
# 2. Синхронізує новий образ
```

## Очищення

```bash
# Видалити Helm releases
helm uninstall django-app -n default
helm uninstall argo-cd-apps -n argocd
helm uninstall argo-cd -n argocd
helm uninstall jenkins -n jenkins
helm uninstall grafana -n monitoring
helm uninstall prometheus -n monitoring

# Почекайте 2 хв (LoadBalancers видаляються)

terraform destroy -auto-approve
```

## Troubleshooting

### Jenkins не запускається

```bash
kubectl get pods -n jenkins
kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller
```

### Argo CD не синхронізує

```bash
kubectl get applications -n argocd
kubectl describe application django-app -n argocd
```

### Образ не пушиться до ECR

```bash
kubectl get sa -n jenkins jenkins-sa -o yaml
# Перевірте annotations: eks.amazonaws.com/role-arn
```

---

Детальна документація: [README.md](./README.md)
