# aws-platform-reference

What this repo does

AWS foundation (low-cost): Terraform backend + optional VPC + budget guardrail (no EKS by default)

Local platform (free): kind + ingress-nginx + Prometheus/Grafana + sample app

Cost safety

enable_vpc=false by default

No EKS in dev

Monthly budget alert set to $5

Quickstart

local-k8s/bootstrap.sh

Grafana access instructions

terraform/envs/bootstrap then terraform/envs/dev