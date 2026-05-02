# Job Application Tracker — Infra

Kubernetes manifests for deploying the Job Application Tracker stack locally using k3d.

## Repositories

| Repo | Description |
|---|---|
| [job_appl_track](https://github.com/alehbelskidev/job_appl_track) | Go REST API |
| [job_appl_track_web](https://github.com/alehbelskidev/job_appl_track_web) | React SPA |
| [job_appl_track_infra](https://github.com/alehbelskidev/job_appl_track_infra) | This repo — K8s manifests |

## Architecture

```
Browser → localhost:80
              ↓
         Traefik Ingress
         /auth, /api  →  Service: api  →  Pod: Go API
         /            →  Service: web  →  Pod: nginx + React
                                ↓
                         Service: postgres
                                ↓
                          Pod: PostgreSQL
```

## Prerequisites

- Docker
- [k3d](https://k3d.io) — `paru -S k3d` or see k3d.io/installation
- kubectl — `paru -S kubectl`

## Local Setup

### 1. Build Docker images

In the API repo:
```bash
docker build -f Dockerfile.prod -t job-tracker-api:latest .
```

In the web repo:
```bash
docker build -f Dockerfile.prod -t job-tracker-web:latest .
```

### 2. Create k3d cluster

```bash
k3d cluster create job-tracker --port "80:80@loadbalancer"
```

### 3. Import images into cluster

```bash
k3d image import job-tracker-api:latest -c job-tracker
k3d image import job-tracker-web:latest -c job-tracker
```

### 4. Configure secrets

Copy the example and fill in values:
```bash
cp .env.example .env
```

Edit `k8s/postgres/secret.yaml` and `k8s/api/secret.yaml` with your values (these are gitignored).

### 5. Deploy

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres/secret.yaml
kubectl apply -f k8s/api/secret.yaml
kubectl apply -f k8s/postgres/pvc.yaml
kubectl apply -f k8s/postgres/deployment.yaml
kubectl apply -f k8s/postgres/service.yaml
```

Wait for PostgreSQL to be ready:
```bash
kubectl get pods -n job-tracker -w
```

Then deploy API and web:
```bash
kubectl apply -f k8s/api/deployment.yaml
kubectl apply -f k8s/api/service.yaml
kubectl apply -f k8s/web/deployment.yaml
kubectl apply -f k8s/web/service.yaml
kubectl apply -f k8s/ingress.yaml
```

### 6. Open

Visit `http://localhost`

## Useful Commands

```bash
# Pod status
kubectl get pods -n job-tracker

# API logs
kubectl logs -n job-tracker -l app=api

# Migration logs
kubectl logs -n job-tracker -l app=api -c migrate

# Restart all deployments
kubectl rollout restart deployment -n job-tracker

# Full reset (WARNING: deletes all data)
kubectl delete namespace job-tracker
kubectl delete pvc --all -A
```

## After Updating Images

```bash
docker build -f Dockerfile.prod -t job-tracker-api:latest .  # in API repo
k3d image import job-tracker-api:latest -c job-tracker
kubectl rollout restart deployment/api -n job-tracker
```

## Notes

- Secrets (`secret.yaml` files) are gitignored. Never commit real credentials.
- PersistentVolumeClaim survives namespace deletion — delete it explicitly when doing a full reset.
- Database migrations run automatically as an init container before the API starts.
- `imagePullPolicy: Never` is set on all deployments — images must be imported via `k3d image import`.
