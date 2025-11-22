# Quick Start - CI/CD Pipeline

Швидкий старт для запуску повного CI/CD pipeline з Jenkins + Argo CD.

## ⚠️ Free Tier Configuration

Проєкт оптимізовано для **AWS Free Tier** з `t3.micro` instances!

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
helm uninstall django-app -n default
helm uninstall argo-cd-apps -n argocd
helm uninstall argo-cd -n argocd
helm uninstall jenkins -n jenkins

# Почекайте 2 хв

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
