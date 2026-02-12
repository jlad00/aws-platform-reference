AWS Platform Reference (Cost-Safe + Local Platform Lab)

This repository demonstrates practical platform engineering skills in two safe, reproducible environments:

Cost-safe AWS foundation with Terraform

Fully local Kubernetes platform with observability

The design intentionally separates cloud infrastructure from platform engineering so experimentation can happen without cost risk.

What This Repository Demonstrates
1️⃣ Terraform: Secure AWS Foundation (Optional)

Located in terraform/

Provides a hardened Terraform backend and optional infrastructure modules.

Included

Secure S3 state bucket

Versioning enabled

Server-side encryption (AES256)

Public access blocked

TLS-only enforcement

Optional DynamoDB state locking (disabled by default)

Optional GitHub OIDC role for CI (disabled by default)

Optional VPC module (disabled by default)

Optional AWS budget alert

Cost Safety

By default:

enable_vpc            = false
enable_github_oidc    = false
enable_dynamodb_lock  = false


Running terraform plan creates no billable infrastructure unless explicitly enabled.

This repository is safe to clone and explore.

2️⃣ Local Kubernetes Platform (Free)

Located in local-k8s/

Runs entirely on:

kind (Kubernetes in Docker)

ingress-nginx

Prometheus + Grafana (Helm)

Sample application with Ingress

No cloud resources required.

Architecture Overview
Local Platform
kind cluster
├── ingress-nginx
├── hello app (Deployment + Service)
└── kube-prometheus-stack
    ├── Prometheus
    ├── Grafana
    └── node-exporter


Access:

App: http://hello.local

Grafana: http://localhost:3000
 (via port-forward)

AWS Bootstrap (Optional)
Terraform (bootstrap)
├── S3 state bucket (secure)
├── Optional DynamoDB lock table
└── Optional GitHub OIDC IAM role


This enables a real-world remote Terraform backend suitable for CI workflows.

🚀 Quickstart: Local Platform Lab
Requirements

Windows:

Docker Desktop (WSL integration enabled)

WSL Ubuntu:

kind

kubectl

helm

curl

Install Tools (WSL)
sudo apt update
sudo apt install -y curl ca-certificates git

# kubectl
KUBECTL_VERSION="v1.29.2"
curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
kubectl version --client

# kind
KIND_VERSION="v0.22.0"
curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
sudo install -m 0755 /tmp/kind /usr/local/bin/kind
kind version

# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

docker version

Create Cluster

From repo root:

kind create cluster --name platform-lab --config local-k8s/kind-config.yaml
kind export kubeconfig --name platform-lab
kubectl config use-context kind-platform-lab >/dev/null
kubectl label node platform-lab-control-plane ingress-ready=true --overwrite

Install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/kind/deploy.yaml
kubectl wait -n ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

Deploy Sample App
kubectl apply -f local-k8s/apps/hello.yaml
kubectl apply -f local-k8s/apps/hello-ingress.yaml

Install Monitoring
kubectl create namespace monitoring >/dev/null 2>&1 || true

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f local-k8s/observability-values.yaml

Access the App

Add to Windows hosts file:

127.0.0.1 hello.local


Open:

http://hello.local

Access Grafana
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80


Open:

http://localhost:3000


Default credentials:

admin / admin

Cleanup
kind delete cluster --name platform-lab

🔁 CI Workflows

Located in .github/workflows/

terraform-ci.yml

terraform fmt

terraform validate

No AWS credentials required

Runs on PRs and pushes

local-platform-ci.yml

Builds sample app container

Validates Kubernetes manifests

This ensures:

Terraform configuration remains valid

Kubernetes YAML remains syntactically correct

CI works without requiring cloud credentials

🎯 Purpose of This Project

This project demonstrates:

Cost-aware infrastructure design

Hardened Terraform backend patterns

Modular IaC structure

Kubernetes bootstrapping with kind

Ingress configuration

Observability stack deployment

CI validation without cloud credentials

Secure GitHub OIDC integration (optional)

It intentionally avoids:

Full EKS production architecture

Enterprise multi-account landing zones

Complex GitOps tooling

This is a focused, practical platform engineering lab designed to showcase transferable skills.