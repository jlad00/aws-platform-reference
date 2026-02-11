#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="platform-lab"

echo "[1/6] Create kind cluster (if missing)"
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  kind create cluster --name "${CLUSTER_NAME}" --config local-k8s/kind-config.yaml
fi

kind export kubeconfig --name "${CLUSTER_NAME}"

echo "[2/6] Ensure ingress-ready label"
kubectl label node "${CLUSTER_NAME}-control-plane" ingress-ready=true --overwrite

echo "[3/6] Install ingress-nginx (idempotent apply)"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/kind/deploy.yaml

echo "[4/6] Wait for ingress controller"
kubectl wait -n ingress-nginx --for=condition=Ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

echo "[5/6] Deploy app + ingress"
kubectl apply -f local-k8s/apps/hello.yaml
kubectl apply -f local-k8s/apps/hello-ingress.yaml

echo "[6/6] Install monitoring stack (Prometheus + Grafana)"
kubectl create namespace monitoring >/dev/null 2>&1 || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring -f local-k8s/observability-values.yaml

echo "Done."
echo "App:     http://hello.local"
echo "Grafana: kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80"
