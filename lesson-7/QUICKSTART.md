# Quick Start Guide - Lesson 7

Швидкий старт для розгортання Django на Kubernetes (EKS) через Terraform та Helm.

## ⚠️ Free Tier Configuration

**Цей проєкт налаштовано для AWS Free Tier:**

- Instance type: `t3.micro` (1 GB RAM)
- Replicas: 1 pod
- HPA: 1-3 pods
- Database: SQLite (без PostgreSQL)

Для production конфігурації дивіться [README.md](./README.md#для-production-або-не-free-tier).

## Передумови

```bash
# Перевірте наявність необхідних інструментів
terraform --version
aws --version
kubectl version --client
helm version
docker --version
```

## Крок 1: Створення інфраструктури (15-20 хв)

```bash
cd lesson-7

# Закоментуйте backend.tf при першому запуску
terraform init
terraform apply

# Після створення S3 - розкоментуйте backend.tf
terraform init -reconfigure
```

## Крок 2: Налаштування kubectl

```bash
# Підключення до EKS кластера
aws eks update-kubeconfig --region eu-north-1 --name lesson-7-eks-cluster

# Перевірка
kubectl get nodes
```

## Крок 3: Білд та пуш Docker образу

```bash
# Автоматично
./build-and-push.sh

# Або вручну
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.eu-north-1.amazonaws.com
cd ../lesson-4
docker build -t lesson-7-django-app:latest .
docker tag lesson-7-django-app:latest ${AWS_ACCOUNT_ID}.dkr.ecr.eu-north-1.amazonaws.com/lesson-7-django-app:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.eu-north-1.amazonaws.com/lesson-7-django-app:latest

# ВАЖЛИВО: Якщо на Free Tier спробувати використати "t3.medium" - тоді отримаєте помилку про Free Tier
# Наразі instance_type в main.tf "t3.micro"
```

## Крок 4: Оновлення Helm values

```bash
# Отримайте ECR URL
terraform output ecr_repository_url

# Оновіть charts/django-app/values.yaml
# Замініть image.repository на ваш ECR URL
```

## Крок 5: Розгортання через Helm

```bash
cd charts/django-app

# Встановлення
helm install django-app . --namespace default

# Перевірка
kubectl get pods
kubectl get service
kubectl get hpa
```

## Крок 6: Доступ до застосунку

```bash
# Отримайте LoadBalancer URL
kubectl get service django-app-django

# Тестування
LOAD_BALANCER_URL=$(kubectl get service django-app-django -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://${LOAD_BALANCER_URL}
```

## Корисні команди

```bash
# Логи
kubectl logs -l app=django-app-django

# Масштабування
kubectl get hpa --watch

# Оновлення
helm upgrade django-app . -f values.yaml

# Видалення
helm uninstall django-app
terraform destroy
```

## Troubleshooting

```bash
# Перевірка подів
kubectl describe pod <pod-name>

# Перевірка образу
aws ecr describe-images --repository-name lesson-7-django-app --region eu-north-1

# Metrics server (якщо HPA не працює)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Детальна документація: [README.md](./README.md)
