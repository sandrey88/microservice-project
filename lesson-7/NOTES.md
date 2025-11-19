# Lesson 7 - Важливі нотатки

## Що реалізовано

✅ **Terraform інфраструктура**:

- EKS кластер з 2 worker nodes (t3.micro)
- VPC з публічними та приватними підмережами
- ECR репозиторій для Docker образів
- S3 + DynamoDB для Terraform state

✅ **Helm Chart для Django**:

- Deployment з 1 подом
- Service типу LoadBalancer
- HPA для автоскейлінгу (1-3 поди)
- ConfigMap зі змінними середовища

✅ **Django застосунок**:

- Працює на SQLite (без PostgreSQL)
- Доступний через LoadBalancer
- Автоматичне масштабування при навантаженні

## Конфігурація для Free Tier

Проєкт налаштовано для роботи в межах AWS Free Tier:

| Параметр       | Free Tier | Production      |
| -------------- | --------- | --------------- |
| Instance Type  | t3.micro  | t3.medium/large |
| RAM            | 1 GB      | 4-8 GB          |
| Replicas       | 1         | 2+              |
| HPA Min/Max    | 1-3       | 2-6             |
| CPU Request    | 100m      | 250m            |
| Memory Request | 128Mi     | 256Mi           |
| Database       | SQLite    | PostgreSQL/RDS  |

## Чому SQLite замість PostgreSQL?

1. **Ресурси**: PostgreSQL потребує додаткових 256-512 MB RAM
2. **Free Tier**: t3.micro має лише 1 GB RAM загалом
3. **Простота**: Для демонстрації Kubernetes функціоналу SQLite достатньо

## Як перейти на PostgreSQL?

Дивіться детальні інструкції в [README.md](./README.md#як-додати-postgresql-до-кластера):

- **Варіант 1**: StatefulSet у Kubernetes
- **Варіант 2**: AWS RDS (рекомендовано)
- **Варіант 3**: Bitnami Helm Chart

## Поточний стан

```bash
# Перевірка
kubectl get pods
# NAME                                 READY   STATUS    RESTARTS   AGE
# django-app-django-578cb9c577-65djq   1/1     Running   0          5m

kubectl get service
# NAME                TYPE           EXTERNAL-IP
# django-app-django   LoadBalancer   a8ff16faf29f246b3a2e55ff7bcdb333...

kubectl get hpa
# NAME                    TARGETS              MINPODS   MAXPODS   REPLICAS
# django-app-django-hpa   cpu: <unknown>/70%   1         3         1

# Тест
curl http://a8ff16faf29f246b3a2e55ff7bcdb333-766783125.eu-north-1.elb.amazonaws.com
# OK: Django is running ✅
```

## Вартість

**Free Tier (перші 12 місяців)**:

- EKS Control Plane: $0.10/год × 730 год = ~$73/міс
- t3.micro nodes: Free Tier (750 год/міс)
- LoadBalancer: ~$16/міс
- NAT Gateway: $0.045/год × 730 = ~$33/міс
- **Загалом**: ~$122/міс

**Після Free Tier**:

- Додатково за t3.micro: ~$15/міс (2 nodes)
- **Загалом**: ~$137/міс

⚠️ **Не забудьте видалити ресурси після тестування!**

```bash
helm uninstall django-app
terraform destroy
```

## Troubleshooting

### Проблеми, які були вирішені:

1. **PostgreSQL connection error**

   - Причина: Django налаштований на PostgreSQL, якого немає
   - Рішення: Змінено на SQLite

2. **Insufficient memory**

   - Причина: 2 поди × 256Mi > 1GB RAM
   - Рішення: Зменшено до 1 поду × 128Mi

3. **Old Docker image**

   - Причина: pullPolicy: IfNotPresent
   - Рішення: Змінено на pullPolicy: Always

4. **Instance type not Free Tier eligible**
   - Причина: t3.medium не підтримується
   - Рішення: Змінено на t3.micro

## Наступні кроки (опційно)

- [ ] Додати PostgreSQL (StatefulSet або RDS)
- [ ] Налаштувати Ingress замість LoadBalancer
- [ ] Додати SSL/TLS сертифікати
- [ ] Налаштувати CI/CD pipeline
- [ ] Додати моніторинг (Prometheus + Grafana)
- [ ] Налаштувати логування (ELK stack)
- [ ] Додати автоскейлінг кластера (Cluster Autoscaler)

## Корисні команди

```bash
# Моніторинг
kubectl get pods --watch
kubectl logs -f <pod-name>
kubectl top pods
kubectl top nodes

# Масштабування
kubectl scale deployment django-app-django --replicas=2
kubectl get hpa --watch

# Debugging
kubectl describe pod <pod-name>
kubectl exec -it <pod-name> -- /bin/bash
kubectl get events --sort-by='.lastTimestamp'

# Helm
helm list
helm status django-app
helm history django-app
helm rollback django-app 1
```
