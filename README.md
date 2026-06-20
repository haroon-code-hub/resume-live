# Live Resume — DevOps & Cloud Project

A production-grade resume app built to demonstrate real DevOps and cloud engineering skills. Not a tutorial project — every tool here is wired together and running on live infrastructure.

**Live at:** `http://3.248.172.104` &nbsp;|&nbsp; **Stack:** Node.js · PostgreSQL · Docker · Kubernetes · AWS · Terraform · GitHub Actions

---

## What This Project Demonstrates

| Area | Implementation |
|---|---|
| **Cloud Infrastructure** | AWS VPC, EC2, Elastic IP provisioned with Terraform |
| **Infrastructure as Code** | Terraform with remote state in S3 + DynamoDB locking |
| **Containers** | Multi-stage Docker build, non-root user, minimal image |
| **Kubernetes** | k3s cluster with Deployments, Services, Ingress, ConfigMaps, Secrets, PVC |
| **CI/CD** | GitHub Actions — build → push to DockerHub → deploy to k3s on every push to `main` |
| **Security** | SSH restricted to known IP, kubeconfig-based deploys (no SSH in pipeline), encrypted state |
| **Reliability** | Health probes, resource limits, 2 replicas, PostgreSQL persistent storage |

---

## Architecture

```
Developer (git push)
        │
        ▼
  GitHub Actions
  ┌─────────────────────────────┐
  │ 1. Build linux/amd64 image  │
  │ 2. Push to DockerHub        │
  │ 3. kubectl set image        │ ← kubeconfig secret (no SSH)
  └─────────────────────────────┘
        │
        ▼
  AWS EC2 t3.micro (eu-west-1)
  ┌─────────────────────────────┐
  │  k3s Kubernetes cluster     │
  │  ┌────────────────────────┐ │
  │  │ Traefik Ingress (:80)  │ │
  │  │ App Deployment (×2)    │ │
  │  │ PostgreSQL + PVC       │ │
  │  └────────────────────────┘ │
  └─────────────────────────────┘
        │
        ▼
  http://3.248.172.104
```

---

## Infrastructure (Terraform)

All infrastructure is defined as code in [`terraform/`](terraform/).

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars  # fill in your values
terraform init
terraform plan
terraform apply
```

**Resources provisioned:**
- VPC with public subnet, internet gateway, route table
- EC2 t3.micro with Ubuntu 24.04 and k3s auto-installed
- Elastic IP (static public IP)
- Security group (HTTP/HTTPS open, SSH restricted to your IP)
- S3 bucket + DynamoDB table for Terraform remote state

**Estimated cost:** ~$0/month on AWS free tier · ~$9/month after

---

## Running Locally

```bash
# Clone and start
docker compose up --build

# App runs at http://localhost:3000
```

---

## Kubernetes Deployment

```bash
# Point kubectl at the cluster
export KUBECONFIG=~/.kube/resume-live-config

# Deploy all resources
kubectl apply -f k8s/

# Check everything is running
kubectl get pods -n live-resume
```

---

## CI/CD Pipeline

Defined in [`.github/workflows/docker-build.yml`](.github/workflows/docker-build.yml).

Every push to `main`:
1. Builds a `linux/amd64` Docker image
2. Pushes to DockerHub with both `latest` and `<git-sha>` tags
3. Deploys to the k3s cluster via kubeconfig (no SSH required)
4. Waits for rollout to complete before marking success

**Required GitHub secrets:**

| Secret | Purpose |
|---|---|
| `DOCKERHUB_USERNAME` | DockerHub login |
| `DOCKERHUB_TOKEN` | DockerHub access token |
| `KUBECONFIG_DATA` | k3s kubeconfig (base64 content of `~/.kube/config`) |

---

## Roadmap

- [x] Containerise app with Docker (multi-stage build, non-root user)
- [x] Deploy to Kubernetes (k3s) with health probes, resource limits, persistent storage
- [x] Provision AWS infrastructure with Terraform (VPC, EC2, S3 remote state)
- [x] CI/CD pipeline with GitHub Actions (build → push → deploy)
- [x] Secure pipeline — kubeconfig-based deploys, no open SSH
- [ ] Helm chart — package k8s manifests for multi-environment deployment
- [ ] TLS/HTTPS — cert-manager + Let's Encrypt via custom domain
- [ ] Observability — Prometheus metrics, Grafana dashboards, alerting
- [ ] Horizontal Pod Autoscaler — scale 2→5 replicas under load
- [ ] GitOps — ArgoCD for declarative, auditable deployments

---

## Project Structure

```
.
├── src/                  # Node.js app
│   ├── server.js
│   ├── db.js
│   └── styles.css
├── k8s/                  # Kubernetes manifests
│   ├── namespace.yaml
│   ├── app-deployment.yaml
│   ├── app-service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── postgres-deployment.yaml
│   ├── postgres-service.yaml
│   └── postgres-pvc.yaml
├── terraform/            # AWS infrastructure as code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── .github/workflows/    # CI/CD pipeline
│   └── docker-build.yml
└── Dockerfile
```
