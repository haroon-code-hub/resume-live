# Live Resume DevOps

A Node.js resume app with PostgreSQL visitor counter. Aim to learn and practice DevOps tools

## Docker Image

````bash
docker pull saeedha/live-resume-devops:latest

## Run with Docker Compose

docker compose up --build

## Kubernetes Deployment

Apply resources:

kubectl apply -f k8s/

## Get Pods

kubectl get pods -n live-resume

## Access App

kubectl port-forward -n live-resume svc/live-resume-service 8080:80

## Monitoring

Install monitoring stack:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

kubectl create namespace monitoring

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring
````

Check monitoring pods:

```bash
kubectl get pods -n monitoring
```

Access Grafana:

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
```

Open:

```text
http://localhost:3000
```

Get Grafana password:

```bash
kubectl get secret kube-prometheus-stack-grafana \
  -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 --decode && echo
```
