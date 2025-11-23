# CI/CD Flow Diagram

## ⚠️ Instance Type Configuration

Цей проєкт налаштовано на `t3.small` instances (3 ноди по 2 vCPU, 2 GB RAM).

**Примітка**: AWS Free Tier блокує t3.medium/t2.medium, тому використовується t3.small з оптимізацією ресурсів.

## Повний процес CI/CD

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                          │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ git push
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      GitHub Repository (Code)                       │
│                   https://github.com/user/django-app                │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ webhook/polling
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                            Jenkins CI                               │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Stage 1: Build & Push Docker Image                          │  │
│  │                                                              │  │
│  │  1. Clone repository                                        │  │
│  │  2. Run Kaniko container                                    │  │
│  │  3. Build Docker image from Dockerfile                      │  │
│  │  4. Tag image: v1.0.${BUILD_NUMBER}                        │  │
│  │  5. Push to ECR (using IRSA IAM Role)                      │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Stage 2: Update Helm Chart Tag                              │  │
│  │                                                              │  │
│  │  1. Clone helm-charts repository                            │  │
│  │  2. Update values.yaml:                                     │  │
│  │     sed -i "s/tag: .*/tag: v1.0.X/" values.yaml            │  │
│  │  3. Git commit & push to main                               │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ git push
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  GitHub Repository (Helm Charts)                    │
│                 https://github.com/user/helm-charts                 │
│                                                                     │
│  charts/django-app/                                                 │
│  ├── Chart.yaml                                                     │
│  ├── values.yaml  ← tag: v1.0.X (updated by Jenkins)              │
│  └── templates/                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Git polling (every 3 min)
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           Argo CD                                   │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Application: django-app                                      │  │
│  │                                                              │  │
│  │  Source:                                                     │  │
│  │    repoURL: https://github.com/user/helm-charts.git         │  │
│  │    path: charts/django-app                                   │  │
│  │    targetRevision: main                                      │  │
│  │                                                              │  │
│  │  Destination:                                                │  │
│  │    server: https://kubernetes.default.svc                    │  │
│  │    namespace: default                                        │  │
│  │                                                              │  │
│  │  Sync Policy:                                                │  │
│  │    automated:                                                │  │
│  │      prune: true                                             │  │
│  │      selfHeal: true                                          │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  Actions:                                                           │
│  1. Detect changes in values.yaml                                  │
│  2. Compare desired state (Git) vs actual state (K8s)              │
│  3. Generate kubectl apply commands                                │
│  4. Apply changes to Kubernetes                                    │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ kubectl apply
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster (EKS)                       │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Deployment: django-app-django                                │  │
│  │                                                              │  │
│  │  Replicas: 2 (Production)                                    │  │
│  │  Image: ECR_URL/project-django-app:v1.0.X                   │  │
│  │                                                              │  │
│  │  Pods:                                                       │  │
│  │  └── django-app-django-xxx-1  (Running)                     │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Service: django-app-django (LoadBalancer)                    │  │
│  │                                                              │  │
│  │  Type: LoadBalancer                                          │  │
│  │  Port: 80 → TargetPort: 8000                                │  │
│  │  External IP: xxx.eu-north-1.elb.amazonaws.com              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ HPA: django-app-django-hpa                                   │  │
│  │                                                              │  │
│  │  Min Replicas: 2 (Production)                                │  │
│  │  Max Replicas: 5 (Production)                                │  │
│  │  Target CPU: 70%                                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTP requests
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                              End Users                              │
│                   http://xxx.elb.amazonaws.com                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Компоненти та їх ролі

### 1. GitHub Repositories

**django-app** (Code Repository):

- Містить Django код
- Містить Dockerfile
- Містить Jenkinsfile
- Тригерить Jenkins при push

**helm-charts** (GitOps Repository):

- Містить Helm charts
- values.yaml оновлюється Jenkins
- Є джерелом правди для Argo CD

### 2. Jenkins (CI)

**Responsibilities**:

- Continuous Integration
- Build Docker images
- Push to ECR
- Update Helm charts in Git

**Components**:

- Jenkins Controller (Master)
- Kaniko Pod (Build agent)
- Git Pod (Git operations)
- Service Account з IRSA для ECR

**Pipeline Stages**:

1. Build & Push Docker Image
2. Update Chart Tag in Git

### 3. Argo CD (CD)

**Responsibilities**:

- Continuous Deployment
- GitOps reconciliation
- Automatic sync
- Self-healing

**Components**:

- Argo CD Server
- Repo Server
- Application Controller
- Application CRD

**Sync Process**:

1. Poll Git repository (every 3 min)
2. Compare desired vs actual state
3. Generate diff
4. Apply changes to Kubernetes
5. Report status

### 4. Amazon ECR

**Responsibilities**:

- Docker image registry
- Image storage
- Image versioning

**Access**:

- Jenkins pushes via IRSA
- EKS worker nodes pull via IAM role

### 5. Kubernetes (EKS)

**Responsibilities**:

- Run application containers
- Load balancing
- Auto-scaling
- Health checks

**Resources**:

- Deployment (manages Pods)
- Service (LoadBalancer)
- ConfigMap (environment variables)
- HPA (auto-scaling)

## Часова лінія деплою

```
T+0:00  Developer: git push to django-app
T+0:05  Jenkins: Webhook received, start pipeline
T+0:10  Jenkins: Kaniko builds Docker image
T+0:15  Jenkins: Push image to ECR (tag: v1.0.42)
T+0:20  Jenkins: Clone helm-charts repo
T+0:21  Jenkins: Update values.yaml (tag: v1.0.42)
T+0:22  Jenkins: Git push to helm-charts
T+0:25  Argo CD: Detect changes in helm-charts
T+0:26  Argo CD: Compare desired vs actual state
T+0:27  Argo CD: Start sync operation
T+0:30  Kubernetes: Pull new image from ECR
T+0:35  Kubernetes: Create new ReplicaSet
T+0:40  Kubernetes: Start new Pods
T+0:45  Kubernetes: Wait for readiness probes
T+0:50  Kubernetes: Terminate old Pods
T+0:55  Argo CD: Sync completed, status: Healthy
T+1:00  End Users: New version is live! 🎉
```

## Security

### IRSA (IAM Roles for Service Accounts)

**Jenkins Service Account**:

```
jenkins-sa → IAM Role → ECR Push Policy
```

**EBS CSI Driver**:

```
ebs-csi-controller-sa → IAM Role → EBS Policy
```

**Worker Nodes**:

```
EC2 Instance → IAM Role → ECR Pull Policy
```

### Secrets Management

**Jenkins Credentials**:

- GitHub PAT stored in JCasC
- Used for Git operations

**Argo CD Repository**:

- GitHub credentials in Secret
- Type: repository

## Monitoring Points

1. **Jenkins**:

   - Pipeline status
   - Build logs
   - Kaniko logs

2. **Argo CD**:

   - Application health
   - Sync status
   - Git commit tracking

3. **Kubernetes**:

   - Pod status
   - HPA metrics
   - Service endpoints

4. **ECR**:
   - Image tags
   - Image scan results
   - Storage usage

## Rollback Strategy

### Automatic (Argo CD)

```bash
# Revert commit in helm-charts
git revert HEAD
git push

# Argo CD auto-syncs to previous version
```

### Manual (kubectl)

```bash
# Rollback deployment
kubectl rollout undo deployment/django-app-django

# Or to specific revision
kubectl rollout undo deployment/django-app-django --to-revision=2
```

### Manual (Argo CD UI)

1. Go to Application
2. Click "History and Rollback"
3. Select previous revision
4. Click "Rollback"

## Best Practices

1. **Always use Git as source of truth**
2. **Never kubectl apply manually** (breaks GitOps)
3. **Tag images with build number** (not latest)
4. **Use automated sync** for faster deployments
5. **Enable self-heal** for resilience
6. **Monitor Argo CD sync status**
7. **Keep Helm charts in separate repo**
8. **Use IRSA** instead of static credentials
9. **Enable image scanning** in ECR
10. **Test in staging** before production
