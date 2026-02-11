# AWS Platform Reference (Cost-Safe + Local Platform Lab)

This repository demonstrates two complementary capabilities:

1. Cost-safe AWS foundation with Terraform  
2. Fully local Kubernetes platform with observability  

The goal is to show practical platform engineering skills without requiring expensive cloud infrastructure.

---

## What This Repo Demonstrates

### 1. Terraform: Safe AWS Foundation

Located in `terraform/`

This provisions:

- Secure S3 Terraform state bucket
  - Versioning enabled
  - Server-side encryption (AES256)
  - Public access blocked
  - TLS-only enforcement
- Optional DynamoDB state locking (disabled by default)
- Optional GitHub OIDC role for CI (disabled by default)
- Optional VPC module (disabled by default)
- Optional budget alert module

**Important:**

- `enable_vpc = false` by default  
- `enable_github_oidc = false` by default  
- `enable_dynamodb_lock = false` by default  

Running `terraform plan` does not create billable infrastructure unless explicitly enabled.

This repo is intentionally safe to clone and explore.

---

### 2. Local Kubernetes Platform (Free)

Located in `local-k8s/`

This provisions locally using:

- kind (Kubernetes-in-Docker)
- ingress-nginx
- Prometheus + Grafana (via Helm)
- Sample hello app with Ingress

Everything runs locally on WSL/Docker Desktop.

No cloud resources required.

---

## Architecture Overview

### Local Platform

kind cluster  
├── ingress-nginx  
├── hello app (Deployment + Service)  
└── kube-prometheus-stack  
  ├── Prometheus  
  ├── Grafana  
  └── node-exporter  

Access:

- App: http://hello.local  
- Grafana: port-forward to localhost:3000  

---

### AWS Bootstrap (Optional)

Terraform (bootstrap)  
├── S3 state bucket (secure)  
├── Optional DynamoDB lock table  
└── Optional GitHub OIDC IAM role  

This provides a secure remote backend suitable for real-world Terraform workflows.

---

## Quickstart: Local Platform

### Requirements

- WSL2  
- Docker Desktop  
- kind  
- kubectl  
- helm  

### Run

```bash
bash local-k8s/bootstrap.sh


Add to Windows hosts file:
127.0.0.1 hello.local

Visit:
http://hello.local

Grafana
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
browse: http://localhost:3000
default creds: admin / admin


Quickstart: AWS Bootstrap (Optional)

Only needed if you want remote Terraform state.

cd terraform/envs/bootstrap
terraform init
terraform apply

Then update terraform/envs/dev/backend.tf with the generated bucket name.

By default, no VPC or EKS is created.

To enable VPC:
enable_vpc = true

To enable GitHub OIDC:
enable_github_oidc = true

-- CI Workflows

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

Purpose of this Repo
This project demonstrates:  
    Cost-aware infrastructure design
    Terraform backend hardening
    Modular IaC patterns
    Kubernetes bootstrapping with kind
    Ingress configuration
    Observability stack deployment
    CI validation without requiring cloud credentials
    Secure GitHub OIDC setup (optional)
It intentionally separates:
    Cloud foundation
    Local platform engineering

So experimentation can happen without cost risk.

What This Repo Is Not
    Not a production EKS reference architecture
    Not a multi-account enterprise landing zone
    Not a full GitOps implementation

It is a focused, practical platform engineering lab designed to show real, transferable skills.

Tech Used
    Terraform 1.6+
    AWS provider v6
    kind
    Kubernetes 1.29
    ingress-nginx
    kube-prometheus-stack (Helm)
    GitHub Actions