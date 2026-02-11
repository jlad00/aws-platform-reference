# aws-platform-reference

A portfolio-friendly platform reference that is **safe-by-default** (minimal AWS spend) and **fully runnable locally**.

## What this repo demonstrates

### Local platform (free)
- kind Kubernetes cluster
- ingress-nginx
- Prometheus + Grafana (kube-prometheus-stack)
- sample app exposed at `http://hello.local`

### AWS foundation (optional / low-cost)
- Terraform S3 backend (with lockfile)
- optional VPC (disabled by default)
- AWS Budget alert ($5) to prevent surprise spend

## Cost safety
- `enable_vpc=false` by default (no VPC/NAT spend)
- no EKS in dev (EKS control plane costs money if left running)
- budget alert at $5

## Quickstart (local platform)
**Prereqs:** Docker Desktop + WSL2 (Ubuntu), `kubectl`, `kind`, `helm`

```bash
./local-k8s/bootstrap.sh
