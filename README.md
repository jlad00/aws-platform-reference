# AWS Platform Reference

**Cost-Safe AWS Foundation + Local Kubernetes Platform Lab**

This repository demonstrates practical platform engineering patterns in two safe, reproducible environments:

- **Cost-aware AWS foundation using Terraform** (optional; safe-by-default)
- **Fully local Kubernetes platform** with ingress + observability (free)

The design intentionally separates cloud infrastructure from platform experimentation so you can learn and validate workflows without cost risk.

---

## What this project demonstrates

### 1) Terraform: secure AWS foundation (optional)

Located in `terraform/`

Provides a hardened remote Terraform backend plus optional infrastructure modules.

#### Bootstrap environment (`terraform/envs/bootstrap`)

Creates a secure Terraform backend:

- S3 state bucket
  - Versioning enabled
  - Server-side encryption (AES256)
  - Public access blocked
  - Bucket owner enforcement
  - TLS-only access policy
  - Lifecycle rule to expire old noncurrent versions (cost control)
- Optional DynamoDB lock table (legacy; not required if using `use_lockfile = true`)
- Optional GitHub Actions OIDC provider + IAM role for Terraform (scoped to repo + branch)
- Tags applied to supported resources

Run:

```bash
cd terraform/envs/bootstrap
terraform init
terraform apply
```

Outputs include the state bucket name and (if enabled) the GitHub Actions role ARN.

#### Dev environment (`terraform/envs/dev`)

Safe-by-default configuration:

```hcl
enable_vpc           = false
enable_github_oidc   = false
enable_dynamodb_lock = false
```

Running `terraform plan` in `terraform/envs/dev` creates **no billable infrastructure** unless you explicitly enable modules (for example `enable_vpc=true`).

Run:

```bash
cd terraform/envs/dev
terraform init
terraform plan
```

#### Reproducible configuration files

For portability (and to avoid committing account-specific values), use examples:

- `terraform/envs/dev/backend.tf.example` → copy to `backend.tf` and set your backend bucket name
- `terraform/envs/*/terraform.tfvars.example` → copy to `terraform.tfvars` and customize

---

### 2) Local Kubernetes platform (free)

Located in `local-k8s/`

Runs entirely on your machine:

- **kind** (Kubernetes in Docker)
- **ingress-nginx**
- **Prometheus + Grafana** (Helm, kube-prometheus-stack)
- Sample **hello app** exposed via Ingress

No cloud resources required.

---

## Architecture

### Local platform

```
kind cluster
├── ingress-nginx
├── hello app (Deployment + Service)
└── kube-prometheus-stack
    ├── Prometheus
    ├── Grafana
    └── node-exporter
```

Access:

- App: `http://hello.local`
- Grafana: `http://localhost:3000` (via port-forward)

### AWS bootstrap (optional)

```
Terraform (bootstrap)
├── S3 state bucket (secure + versioned + encrypted)
├── Optional DynamoDB lock table
└── Optional GitHub OIDC IAM role
```

---

## Repository structure

```
.github/workflows/
app/
local-k8s/
terraform/
  envs/
    bootstrap/
    dev/
  modules/
    budget/
    vpc/
    _optional/
```

---

## Quickstart: local platform lab

### Requirements

Windows:

- Docker Desktop (WSL integration enabled)

WSL Ubuntu:

- kind
- kubectl
- helm
- curl

### Install tools (WSL)

```bash
sudo apt update
sudo apt install -y curl ca-certificates git
```

#### kubectl

```bash
KUBECTL_VERSION="v1.29.2"
curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
kubectl version --client
```

#### kind

```bash
KIND_VERSION="v0.22.0"
curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
sudo install -m 0755 /tmp/kind /usr/local/bin/kind
kind version
```

#### helm

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

Verify Docker:

```bash
docker version
```

### Create cluster

From repo root:

```bash
kind create cluster --name platform-lab --config local-k8s/kind-config.yaml
kind export kubeconfig --name platform-lab
kubectl config use-context kind-platform-lab
kubectl label node platform-lab-control-plane ingress-ready=true --overwrite
```

### Install ingress-nginx

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/kind/deploy.yaml

kubectl wait -n ingress-nginx   --for=condition=Ready pod   --selector=app.kubernetes.io/component=controller   --timeout=180s
```

### Deploy sample app

```bash
kubectl apply -f local-k8s/apps/hello.yaml
kubectl apply -f local-k8s/apps/hello-ingress.yaml
```

### Install monitoring

```bash
kubectl create namespace monitoring || true

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack   -n monitoring   -f local-k8s/observability-values.yaml
```

### Access the app

Add to Windows hosts file:

```
127.0.0.1 hello.local
```

Open:

- `http://hello.local`

### Access Grafana

```bash
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
```

Open:

- `http://localhost:3000`

Default credentials:

- `admin / admin`

### Cleanup

```bash
kind delete cluster --name platform-lab
```

---

## CI workflows

Located in `.github/workflows/`

### `terraform-ci.yml`

- `terraform fmt -check -recursive`
- `terraform validate` for bootstrap + dev
- `tflint` (AWS ruleset)
- No AWS credentials required
- Runs on PRs and pushes that touch `terraform/**`

### `local-platform-ci.yml`

- Builds sample app container image
- Validates Kubernetes manifests with `kubeconform`
- Runs on PRs and pushes that touch `local-k8s/**`, `app/**`, and docs

---

## Design intent

This project is intentionally focused and transferable. It demonstrates:

- Cost-aware infrastructure design
- Hardened Terraform backend patterns
- Modular IaC structure
- Secure GitHub OIDC integration (optional)
- CI validation without cloud credentials
- Kubernetes bootstrapping with kind
- Ingress configuration
- Observability stack deployment

It intentionally avoids:

- Full production EKS architecture
- Enterprise landing zones / multi-account AWS design
- Complex GitOps operators and HA cluster patterns

If you're hiring for a platform/infrastructure role, this repo is meant to show how I think: safe defaults, reproducibility, and operational hygiene.
