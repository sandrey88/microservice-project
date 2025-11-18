# Lesson 5: Terraform Infrastructure на AWS

Цей проєкт створює повну інфраструктуру на AWS за допомогою Terraform, включаючи:

- S3 бакет для зберігання стейт-файлів Terraform
- DynamoDB таблицю для блокування стейтів
- VPC з публічними та приватними підмережами
- ECR репозиторій для Docker-образів

!!! Поточний регіон в проєкті - "eu-north-1", за потреби його можна змінити.

## Структура проєкту

```
lesson-5/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               # Загальне виведення ресурсів
│
├── modules/                 # Каталог з усіма модулями
│   │
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакета
│   │   ├── dynamodb.tf      # Створення DynamoDB
│   │   ├── variables.tf     # Змінні для S3
│   │   └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway, NAT Gateway
│   │   ├── routes.tf        # Налаштування маршрутизації
│   │   ├── variables.tf     # Змінні для VPC
│   │   └── outputs.tf       # Виведення інформації про VPC
│   │
│   └── ecr/                 # Модуль для ECR
│       ├── ecr.tf           # Створення ECR репозиторію
│       ├── variables.tf     # Змінні для ECR
│       └── outputs.tf       # Виведення URL репозиторію ECR
│
└── README.md                # Документація проєкту
```

## Вимоги

- Terraform >= 1.0
- AWS CLI налаштований з credentials
- AWS акаунт з правами на створення ресурсів

## Опис модулів

### 1. S3-Backend модуль

**Призначення**: Створює S3 бакет для зберігання Terraform state файлів та DynamoDB таблицю для блокування стейтів.

**Ресурси**:

- `aws_s3_bucket` - S3 бакет для стейтів
- `aws_s3_bucket_versioning` - Версіонування бакета
- `aws_s3_bucket_ownership_controls` - Контроль власності
- `aws_dynamodb_table` - Таблиця для блокування стейтів

**Змінні**:

- `bucket_name` - Ім'я S3 бакета
- `table_name` - Ім'я DynamoDB таблиці

**Outputs**:

- `s3_bucket_name` - Назва створеного S3 бакета
- `dynamodb_table_name` - Назва створеної DynamoDB таблиці

### 2. VPC модуль

**Призначення**: Створює повну мережеву інфраструктуру з публічними та приватними підмережами.

**Ресурси**:

- `aws_vpc` - Virtual Private Cloud
- `aws_subnet` - 3 публічні та 3 приватні підмережі
- `aws_internet_gateway` - Internet Gateway для публічних підмереж
- `aws_nat_gateway` - NAT Gateway для приватних підмереж
- `aws_eip` - Elastic IP для NAT Gateway
- `aws_route_table` - Таблиці маршрутизації
- `aws_route` - Маршрути
- `aws_route_table_association` - Асоціації підмереж з таблицями маршрутів

**Змінні**:

- `vpc_cidr_block` - CIDR блок для VPC (наприклад, "10.0.0.0/16")
- `public_subnets` - Список CIDR блоків для публічних підмереж
- `private_subnets` - Список CIDR блоків для приватних підмереж
- `availability_zones` - Список зон доступності
- `vpc_name` - Ім'я VPC

**Outputs**:

- `vpc_id` - ID створеної VPC
- `public_subnets` - Список ID публічних підмереж
- `private_subnets` - Список ID приватних підмереж
- `internet_gateway_id` - ID Internet Gateway
- `nat_gateway_id` - ID NAT Gateway

### 3. ECR модуль

**Призначення**: Створює ECR (Elastic Container Registry) репозиторій для зберігання Docker-образів.

**Ресурси**:

- `aws_ecr_repository` - ECR репозиторій
- `aws_ecr_lifecycle_policy` - Політика lifecycle (зберігає останні 10 образів)
- `aws_ecr_repository_policy` - Політика доступу до репозиторію

**Змінні**:

- `ecr_name` - Назва ECR репозиторію
- `scan_on_push` - Автоматичне сканування образів при push (true/false)

**Outputs**:

- `repository_url` - URL репозиторію ECR
- `repository_arn` - ARN репозиторію ECR
- `repository_name` - Назва репозиторію ECR

## Інструкція з використання

### Крок 1: Перший запуск (створення S3 та DynamoDB)

⚠️ **ВАЖЛИВО**: При першому запуску потрібно закоментувати бекенд у файлі `backend.tf`, оскільки S3 бакет ще не існує.

1. Відкрийте файл `backend.tf` та закоментуйте весь вміст:

```hcl
# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-andrii-microservice"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "eu-north-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
```

2. Ініціалізуйте Terraform:

```bash
terraform init
```

3. Перегляньте план:

```bash
terraform plan
```

4. Застосуйте конфігурацію:

```bash
terraform apply
```

### Крок 2: Налаштування бекенду

Після створення S3 та DynamoDB:

1. Розкоментуйте вміст файлу `backend.tf`

2. Повторно ініціалізуйте Terraform з новим бекендом:

```bash
terraform init -reconfigure
```

Terraform запитає, чи хочете ви перенести локальний стейт у S3. Введіть `yes`.

### Крок 3: Подальша робота

Тепер ви можете працювати з інфраструктурою:

```bash
# Перегляд плану змін
terraform plan

# Застосування змін
terraform apply

# Перегляд поточного стану
terraform show

# Перегляд outputs
terraform output

# Видалення всієї інфраструктури
terraform destroy
```

## Основні команди Terraform

| Команда              | Опис                                              |
| -------------------- | ------------------------------------------------- |
| `terraform init`     | Ініціалізація Terraform, завантаження провайдерів |
| `terraform plan`     | Перегляд змін, які будуть застосовані             |
| `terraform apply`    | Застосування змін до інфраструктури               |
| `terraform destroy`  | Видалення всієї інфраструктури                    |
| `terraform output`   | Перегляд outputs                                  |
| `terraform show`     | Перегляд поточного стану                          |
| `terraform fmt`      | Форматування .tf файлів                           |
| `terraform validate` | Валідація конфігурації                            |

## Outputs проєкту

Після успішного `terraform apply` ви отримаєте:

- **s3_bucket_name** - Назва S3 бакета для стейтів
- **dynamodb_table_name** - Назва DynamoDB таблиці
- **vpc_id** - ID створеної VPC
- **public_subnets** - Список ID публічних підмереж
- **private_subnets** - Список ID приватних підмереж
- **internet_gateway_id** - ID Internet Gateway
- **nat_gateway_id** - ID NAT Gateway
- **ecr_repository_url** - URL ECR репозиторію
- **ecr_repository_arn** - ARN ECR репозиторію

## ⚠️ ВАЖЛИВІ ПОПЕРЕДЖЕННЯ

### Витрати на AWS

При роботі з AWS ресурсами пам'ятайте:

- **NAT Gateway** - коштує ~$0.0xy/годину + трафік
- **Elastic IP** - безкоштовний, якщо використовується
- **S3** - оплата за зберігання та запити
- **ECR** - оплата за зберігання образів

**Завжди видаляйте невикористані ресурси командою `terraform destroy`!**

### Порядок відновлення після terraform destroy

Якщо ви виконали `terraform destroy` і видалили всю інфраструктуру, включно з S3 та DynamoDB:

1. Закоментуйте `backend.tf`
2. Виконайте `terraform init`
3. Виконайте `terraform apply` (створяться S3 та DynamoDB)
4. Розкоментуйте `backend.tf`
5. Виконайте `terraform init -reconfigure`

## Налаштування AWS credentials

Перед використанням переконайтеся, що AWS CLI налаштований:

```bash
# Налаштування credentials
aws configure

# Перевірка поточного користувача
aws sts get-caller-identity
```

Або використовуйте змінні оточення:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-north-1"
```

## Troubleshooting

### Помилка: "Error: Backend initialization required"

**Рішення**: Виконайте `terraform init` або `terraform init -reconfigure`

### Помилка: "Error: NoSuchBucket"

**Рішення**: S3 бакет ще не створений. Закоментуйте `backend.tf` і створіть інфраструктуру спочатку.

### Помилка: "Error: ResourceAlreadyExistsException"

**Рішення**: Ресурс вже існує. Імпортуйте його або змініть назву.

### Помилка: "BucketNotEmpty" при terraform destroy

**Проблема**: S3 бакет містить версії файлів і не може бути видалений.

**Рішення**:

```bash
# 1. Видалити всі версії об'єктів з бакета
aws s3api delete-objects --bucket terraform-state-andrii-microservice --region eu-north-1 \
  --delete "$(aws s3api list-object-versions --bucket terraform-state-andrii-microservice \
  --region eu-north-1 --output json --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# 2. Видалити delete markers (якщо є)
aws s3api delete-objects --bucket terraform-state-andrii-microservice --region eu-north-1 \
  --delete "$(aws s3api list-object-versions --bucket terraform-state-andrii-microservice \
  --region eu-north-1 --output json --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"

# 3. Видалити сам бакет
aws s3api delete-bucket --bucket terraform-state-andrii-microservice --region eu-north-1

# 4. Очистити локальний стейт
rm -f terraform.tfstate terraform.tfstate.backup .terraform/terraform.tfstate
```

### Помилка: "Error releasing the state lock" після destroy

**Проблема**: DynamoDB таблиця вже видалена, але Terraform намагається звільнити lock.

**Рішення**: Це нормально після `terraform destroy`, який видалив DynamoDB. Просто очистіть локальний стейт:

```bash
rm -f terraform.tfstate terraform.tfstate.backup .terraform/terraform.tfstate
```

⚠️ Для production: краще НЕ використовувати force_destroy, щоб уникнути випадкового видалення даних.
