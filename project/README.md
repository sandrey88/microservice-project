# Project: CI/CD з Jenkins + Argo CD + Terraform + Helm

Повний CI/CD pipeline для Django застосунку з автоматичним білдом, деплоєм та синхронізацією через GitOps.

## ⚠️ AWS Free Tier Configuration

**Цей проєкт оптимізовано для AWS Free Tier!**

- **Instance Type**: `t3.micro` (750 годин/міс безкоштовно)
- **Nodes**: 2× t3.micro (1 GB RAM кожна)
- **Resources**: Мінімізовані для роботи на t3.micro
- **Replicas**: 1 pod за замовчуванням (замість 2)
- **HPA**: 1-3 pods (замість 2-6)

### Для Production

Якщо ви не на Free Tier, змініть в `main.tf`:

```hcl
instance_type = "t3.medium"  # або t3.large
desired_size  = 3
```

І в `charts/django-app/values.yaml`:

```yaml
replicaCount: 2
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

## 🎯 Що реалізовано

### Інфраструктура (Terraform)

- **S3 + DynamoDB**: Backend для Terraform state
- **VPC**: Публічні та приватні підмережі
- **ECR**: Docker registry для образів
- **EKS**: Kubernetes кластер з EBS CSI Driver
- **Jenkins**: CI сервер з автоматичною конфігурацією (JCasC)
- **Argo CD**: GitOps CD інструмент з автоматичною синхронізацією

### CI/CD Pipeline

1. **Jenkins** збирає Docker образ через Kaniko
2. **Jenkins** пушить образ до ECR
3. **Jenkins** оновлює тег в Helm chart (values.yaml)
4. **Argo CD** автоматично виявляє зміни в Git
5. **Argo CD** синхронізує новий образ в Kubernetes

## 📁 Структура проєкту

```
project/
├── main.tf                      # Головний Terraform файл
├── backend.tf                   # S3 backend конфігурація
├── outputs.tf                   # Outputs всіх модулів
├── variables.tf                 # Змінні проєкту
├── terraform.tfvars.example     # Приклад змінних
├── Jenkinsfile                  # CI pipeline
│
├── modules/
│   ├── s3-backend/              # S3 + DynamoDB
│   ├── vpc/                     # VPC з підмережами
│   ├── ecr/                     # ECR репозиторій
│   ├── eks/                     # EKS кластер + EBS CSI Driver
│   │   ├── eks.tf
│   │   ├── node.tf
│   │   ├── aws_ebs_csi_driver.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── jenkins/                 # Jenkins з Helm + JCasC
│   │   ├── jenkins.tf
│   │   ├── values.yaml
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── providers.tf
│   └── argo-cd/                 # Argo CD з Applications
│       ├── argo_cd.tf
│       ├── values.yaml
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       └── charts/              # Helm chart для Argo Applications
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
│
└── charts/
    └── django-app/              # Helm chart для Django
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

## 🚀 Швидкий старт

### Передумови

```bash
# Встановлені інструменти
terraform --version  # >= 1.0
aws --version
kubectl version --client
helm version
git --version

# AWS credentials налаштовані
aws configure
```

### Крок 1: Підготовка репозиторіїв

Вам потрібно **2 Git репозиторії**:

1. **Репозиторій з кодом** (Django app + Jenkinsfile)
2. **Репозиторій з Helm charts** (для Argo CD)

```bash
# Створіть 2 репозиторії на GitHub:
# 1. django-app (для коду)
# 2. helm-charts (для charts)

# Клонуйте репозиторій з кодом
git clone https://github.com/YOUR_USERNAME/django-app.git
cd django-app

# Скопіюйте Django код та Jenkinsfile
cp -r /path/to/lesson-4/* .
cp /path/to/project/Jenkinsfile .

# Commit and push
git add .
git commit -m "Initial Django app with Jenkinsfile"
git push origin main

# Клонуйте репозиторій для Helm charts
cd ..
git clone https://github.com/YOUR_USERNAME/helm-charts.git
cd helm-charts

# Створіть структуру
mkdir -p charts/django-app
cp -r /path/to/project/charts/django-app/* charts/django-app/

# Commit and push
git add .
git commit -m "Initial Helm chart for Django"
git push origin main
```

### Крок 2: Створення GitHub Personal Access Token

1. Перейдіть на https://github.com/settings/tokens
2. Generate new token (classic)
3. Виберіть scopes: `repo` (full control)
4. Збережіть токен - він знадобиться для Terraform

### Крок 3: Налаштування Terraform змінних

```bash
cd project

# Створіть terraform.tfvars з ваших даних
cp terraform.tfvars.example terraform.tfvars

# Відредагуйте terraform.tfvars
nano terraform.tfvars
```

```hcl
# terraform.tfvars
github_username = "your-github-username"
github_token    = "ghp_xxxxxxxxxxxxxxxxxxxx"
github_repo_url = "https://github.com/your-username/django-app.git"
helm_repo_url   = "https://github.com/your-username/helm-charts.git"
```

### Крок 4: Оновлення конфігурацій

#### 4.1 Оновіть ECR URL в Jenkinsfile

```bash
# Отримайте ваш AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo $AWS_ACCOUNT_ID

# Відредагуйте Jenkinsfile
nano Jenkinsfile
```

Замініть:

```groovy
ECR_REGISTRY = "YOUR_AWS_ACCOUNT_ID.dkr.ecr.eu-north-1.amazonaws.com"
```

На:

```groovy
ECR_REGISTRY = "123456789012.dkr.ecr.eu-north-1.amazonaws.com"  # ваш Account ID
```

#### 4.2 Оновіть Helm chart values.yaml

```bash
nano charts/django-app/values.yaml
```

Замініть:

```yaml
image:
  repository: YOUR_AWS_ACCOUNT_ID.dkr.ecr.eu-north-1.amazonaws.com/project-django-app
```

На:

```yaml
image:
  repository: 123456789012.dkr.ecr.eu-north-1.amazonaws.com/project-django-app
```

### Крок 5: Розгортання інфраструктури

```bash
# Перейдіть в директорію проєкту
cd project

# Ініціалізація Terraform
terraform init

# Перевірка плану
terraform plan

# Застосування (створення інфраструктури)
# ⚠️ Це займе ~15-20 хвилин
terraform apply

# Після успішного apply, розкоментуйте backend.tf
nano backend.tf  # розкоментуйте блок terraform

# Міграція state до S3
terraform init -reconfigure
```

### Крок 6: Налаштування kubectl

```bash
# Оновіть kubeconfig для доступу до EKS
aws eks update-kubeconfig --region eu-north-1 --name project-eks-cluster

# Перевірте підключення
kubectl get nodes
kubectl get pods --all-namespaces
```

### Крок 7: Доступ до Jenkins

```bash
# Отримайте URL Jenkins
JENKINS_URL=$(kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Jenkins URL: http://$JENKINS_URL"

# Логін: admin
# Пароль: admin123
```

**В Jenkins UI:**

1. Перейдіть на головну сторінку
2. Знайдіть job `seed-job` (створений автоматично через JCasC)
3. Запустіть `seed-job` - він створить `django-ci-cd` pipeline
4. Запустіть `django-ci-cd` pipeline

### Крок 8: Доступ до Argo CD

```bash
# Отримайте URL Argo CD
ARGOCD_URL=$(kubectl get svc -n argocd argo-cd-argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Argo CD URL: https://$ARGOCD_URL"

# Отримайте admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
echo "Argo CD Password: $ARGOCD_PASSWORD"

# Логін: admin
# Пароль: $ARGOCD_PASSWORD
```

**В Argo CD UI:**

1. Знайдіть application `django-app`
2. Перевірте статус синхронізації
3. Натисніть "Sync" якщо потрібно

### Крок 9: Перевірка Django застосунку

```bash
# Отримайте URL Django app
DJANGO_URL=$(kubectl get svc django-app-django -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Django URL: http://$DJANGO_URL"

# Перевірте
curl http://$DJANGO_URL
```

## 🔄 Робочий процес CI/CD

### Автоматичний деплой

1. Внесіть зміни в Django код:

```bash
cd django-app
# Змініть код
git add .
git commit -m "Update feature X"
git push origin main
```

2. Jenkins автоматично:

   - Виявить зміни в Git (через webhook або polling)
   - Запустить pipeline `django-ci-cd`
   - Зібере Docker образ через Kaniko
   - Запушить образ до ECR з новим тегом (v1.0.X)
   - Оновить `values.yaml` в helm-charts репозиторії

3. Argo CD автоматично:
   - Виявить зміни в helm-charts репозиторії
   - Синхронізує новий образ в Kubernetes
   - Оновить поди з новою версією

### Ручна синхронізація

```bash
# Через Argo CD CLI
argocd app sync django-app

# Або через UI
# Applications -> django-app -> Sync
```

## 📊 Моніторинг та перевірка

### Перевірка Jenkins pipeline

```bash
# Логи Jenkins pod
kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller -f

# Перевірка Service Account
kubectl get sa -n jenkins jenkins-sa -o yaml

# Перевірка IAM Role
aws iam get-role --role-name project-eks-cluster-jenkins-kaniko-role
```

### Перевірка Argo CD

```bash
# Статус applications
kubectl get applications -n argocd

# Детальна інформація
kubectl describe application django-app -n argocd

# Логи Argo CD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f
```

### Перевірка Django deployment

```bash
# Поди
kubectl get pods -l app=django-app-django

# Логи
kubectl logs -l app=django-app-django -f

# HPA
kubectl get hpa

# Service
kubectl get svc django-app-django
```

## 🔧 Troubleshooting

### Jenkins не може пушити до ECR

**Проблема**: `unauthorized: authentication required`

**Рішення**:

```bash
# Перевірте IAM роль
kubectl get sa -n jenkins jenkins-sa -o yaml

# Перевірте annotations
# Має бути: eks.amazonaws.com/role-arn: arn:aws:iam::XXX:role/...

# Перевірте IAM політику
aws iam get-role-policy --role-name project-eks-cluster-jenkins-kaniko-role --policy-name project-eks-cluster-jenkins-kaniko-ecr-policy
```

### Argo CD не синхронізує зміни

**Проблема**: Application в стані `OutOfSync`

**Рішення**:

```bash
# Перевірте repository credentials
kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=repository

# Перевірте логи
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server

# Ручна синхронізація
kubectl patch application django-app -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

### Поди не запускаються

**Проблема**: `ImagePullBackOff`

**Рішення**:

```bash
# Перевірте образ в ECR
aws ecr describe-images --repository-name project-django-app --region eu-north-1

# Перевірте image pull secrets
kubectl get pods -l app=django-app-django -o yaml | grep -A 5 imagePullSecrets

# Перевірте worker nodes IAM роль
# Має мати AmazonEC2ContainerRegistryReadOnly policy
```

### EBS CSI Driver не працює

**Проблема**: PVC в стані `Pending`

**Рішення**:

```bash
# Перевірте EBS CSI Driver addon
aws eks describe-addon --cluster-name project-eks-cluster --addon-name aws-ebs-csi-driver

# Перевірте OIDC Provider
aws iam list-open-id-connect-providers

# Перевірте Storage Class
kubectl get sc
kubectl describe sc ebs-sc
```

⚠️ **Не забудьте видалити ресурси після тестування!**

## 🧹 Очищення ресурсів

```bash
# 1. Видаліть Helm releases
helm uninstall django-app -n default
helm uninstall argo-cd-apps -n argocd
helm uninstall argo-cd -n argocd
helm uninstall jenkins -n jenkins

# 2. Почекайте поки LoadBalancers видаляться (~2 хв)
kubectl get svc --all-namespaces | grep LoadBalancer

# 3. Видаліть образи з ECR
aws ecr batch-delete-image \
  --repository-name project-django-app \
  --region eu-north-1 \
  --image-ids imageTag=latest

# 4. Terraform destroy
terraform destroy

# 5. Видаліть S3 bucket вручну (якщо потрібно)
aws s3 rb s3://terraform-state-andrii-project --force
```

## 📚 Додаткові ресурси

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Kaniko Documentation](https://github.com/GoogleContainerTools/kaniko)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Helm Documentation](https://helm.sh/docs/)
