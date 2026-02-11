# Platform Lab Runbook (local)

## Start / verify cluster
- `kind get clusters`
- `kubectl get nodes`
- `kubectl get pods -A`

## Access app
- `http://hello.local` (Windows hosts file maps to 127.0.0.1)

## Access Grafana
- `kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80`
- Open `http://localhost:3000` (admin/admin)

## Common issues
### Ingress controller Pending
- Ensure node has label `ingress-ready=true`:
  - `kubectl label node platform-lab-control-plane ingress-ready=true`
