# CNZ 2026 Demo – Voting API

A simple conference talk voting API deployed on Amazon EKS via ArgoCD. Used to demonstrate GitOps workflows and the AWS DevOps Agent's debugging capabilities.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Liveness probe – always returns 200 |
| `GET` | `/ready` | Readiness probe – checks for config file at `APP_CONFIG_PATH` |
| `GET` | `/votes` | Returns all current votes |
| `POST` | `/votes/{talk}` | Increment vote count for a talk |

## Folder Structure

```
.
├── apps/voting-api/       # Kubernetes manifests (synced by ArgoCD)
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── argocd/                # GitOps resources
│   ├── application.yaml   # ArgoCD Application definition
│   └── cluster-secret.yaml# Local cluster registration for EKS managed ArgoCD
└── code/                  # Application source code
    ├── main.py
    ├── requirements.txt
    └── Dockerfile
```

## Architecture

- **Runtime**: Python 3.13 + FastAPI
- **Container Registry**: Amazon ECR (`209479284687.dkr.ecr.eu-central-1.amazonaws.com/demo-app`)
- **Orchestration**: Amazon EKS (Auto Mode)
- **GitOps**: EKS managed ArgoCD capability
- **Exposure**: AWS Network Load Balancer (Service type `LoadBalancer`)

## Demo Failure Scenarios

The application is designed with intentional failure injection points:

| Scenario | How to trigger | Observable symptom |
|----------|---------------|-------------------|
| Liveness probe failure | Change probe path to `/healthz` | CrashLoopBackOff, 404 in events |
| Readiness probe failure | Remove ConfigMap volume mount | Pod running but 0/1 Ready |
| OOMKilled | Set memory limit to `10Mi` | Pod restarts with OOMKilled reason |
| ImagePullBackOff | Use non-existent image tag | Pod stuck in Pending |
