# Development Guide

Development workflow and best practices for the ArgoCD GitOps repository.

## Local Development Setup

### Prerequisites

```bash
# Install required tools
# kubectl
curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# k3s (if not already running)
curl -sfL https://get.k3s.io | sh -
```

### Verify Cluster Access

```bash
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

## Development Workflow

### 1. Make Changes

Edit application configuration:

```bash
# Example: Update website image version
vim apps/website/values.yaml
```

### 2. Validate Changes

```bash
# Lint Helm chart
helm lint apps/website/

# Dry-run template rendering
helm template website-release apps/website/ --namespace website

# Validate YAML
kubectl apply -f apps/website/ --dry-run=client

# Validate ArgoCD Application
kubectl apply -f argocd/applications/website.yaml --dry-run=client
```

### 3. Test Locally (Optional)

```bash
# Install/upgrade Helm release in test cluster
helm install website-test apps/website/ \
  --namespace website-test \
  --create-namespace \
  --dry-run

# Or with actual deployment
helm install website-test apps/website/ \
  --namespace website-test \
  --create-namespace
```

### 4. Commit and Push

```bash
# Stage changes
git add apps/website/values.yaml

# Commit with meaningful message
git commit -m "feat: update website nginx image to 1.25"

# Push to repository
git push origin main
```

### 5. Monitor Sync

```bash
# Watch ArgoCD sync
kubectl get application -n argocd -w

# Or check specific app
kubectl describe application website -n argocd

# View detailed events
kubectl logs -n argocd deployment/argocd-application-controller | grep website
```

## Adding a New Application

### Step 1: Create Helm Chart

```bash
# Create directory structure
mkdir -p apps/myapp/templates

# Create Chart.yaml
cat > apps/myapp/Chart.yaml << 'EOF'
apiVersion: v2
name: myapp
description: A Helm chart for myapp
type: application
version: 1.0.0
appVersion: "1.0.0"
EOF

# Create values.yaml with default configuration
cat > apps/myapp/values.yaml << 'EOF'
replicaCount: 2
image:
  repository: myapp
  tag: "latest"
  pullPolicy: IfNotPresent
service:
  type: ClusterIP
  port: 80
EOF

# Create templates
cat > apps/myapp/templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "myapp.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  # ... rest of template
EOF
```

### Step 2: Create Helper Templates

Copy `_helpers.tpl` from existing chart:

```bash
cp apps/website/templates/_helpers.tpl apps/myapp/templates/_helpers.tpl

# Update the template names in _helpers.tpl
sed -i 's/website/myapp/g' apps/myapp/templates/_helpers.tpl
sed -i 's/Website/Myapp/g' apps/myapp/templates/_helpers.tpl
```

### Step 3: Create ArgoCD Application

```bash
cat > argocd/applications/myapp.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: k3s-apps
  source:
    repoURL: https://github.com/yourusername/dijitle.com
    targetRevision: HEAD
    path: apps/myapp
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

### Step 4: Commit and Deploy

```bash
git add apps/myapp/ argocd/applications/myapp.yaml
git commit -m "feat: add myapp application"
git push origin main

# ArgoCD automatically detects and deploys
kubectl get application -n argocd
```

## Environment-Specific Configuration

### Method 1: Multiple values files

```bash
# Base values
apps/website/values.yaml

# Environment-specific
apps/website/values-dev.yaml
apps/website/values-prod.yaml
```

Update Application spec:

```yaml
source:
  repoURL: <repo>
  path: apps/website
  helm:
    valueFiles:
      - values.yaml
      - values-prod.yaml # For production
```

### Method 2: Kustomize Overlays

Create directory structure:

```
apps/website/
├── base/
│   ├── Chart.yaml
│   └── values.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml
```

## Troubleshooting Development Issues

### Application sync fails

```bash
# Check application status
kubectl describe application website -n argocd

# Check sync errors
kubectl get application website -n argocd -o jsonpath='{.status.conditions}' | jq

# Examine controller logs
kubectl logs -n argocd deployment/argocd-application-controller | tail -50

# Check if namespace exists
kubectl get namespace website
```

### Helm rendering errors

```bash
# Test template rendering
helm template website apps/website/

# With custom values
helm template website apps/website/ -f apps/website/values-prod.yaml

# Check template syntax
helm lint apps/website/ -v
```

### Pod not starting

```bash
# Check pod status
kubectl get pods -n website -o wide

# View pod events
kubectl describe pod <pod-name> -n website

# Check logs
kubectl logs <pod-name> -n website
kubectl logs <pod-name> -n website --previous  # Previous instance
```

### Resource limit issues

```bash
# Check resource usage
kubectl top pods -n website
kubectl top nodes

# Check limits
kubectl describe nodes | grep -A 5 "Allocated resources"

# Adjust resource requests in values.yaml
```

## Commit Message Conventions

Follow conventional commits:

```
feat: add new feature
fix: fix a bug
docs: documentation changes
style: formatting changes
refactor: code refactoring
test: test updates
chore: maintenance tasks
```

Examples:

```bash
git commit -m "feat: add api autoscaling configuration"
git commit -m "fix: correct service selector labels"
git commit -m "docs: update SETUP.md with k3s instructions"
```

## Testing Best Practices

### Helm Template Testing

```bash
# Create test namespace
kubectl create namespace helm-test

# Test installation
helm install test-release apps/website/ \
  --namespace helm-test \
  --values apps/website/values.yaml

# Verify resources
kubectl get all -n helm-test

# Cleanup
kubectl delete namespace helm-test
```

### Schema Validation

```bash
# Validate Kubernetes manifests
kubectl apply -f apps/website/templates/ --dry-run=client

# Check ArgoCD Application schema
kubectl explain Application
```

### Integration Testing

```bash
# Deploy and verify
helm install test-app apps/website/ --namespace test --create-namespace

# Test connectivity
kubectl port-forward -n test svc/test-app-website 8080:80
curl http://localhost:8080

# Cleanup
helm uninstall test-app -n test
kubectl delete namespace test
```

## Performance Optimization

### Helm Chart Performance

```bash
# Render templates efficiently
# Limit template files to necessary ones
# Use relative paths for includes

# Test rendering speed
time helm template website apps/website/
```

### ArgoCD Performance

```bash
# Check sync performance
kubectl logs -n argocd deployment/argocd-application-controller | grep "sync"

# Adjust sync frequency if needed
# Edit AppProject for sync policy
```

## Security Best Practices

### Secrets Management

```bash
# Never commit secrets to Git
# Use Kubernetes secrets with ArgoCD

# Option 1: Manual secret creation
kubectl create secret generic app-secret \
  --from-literal=db-password=mypassword \
  -n website

# Option 2: External Secrets Operator
# Configure external secret source
# Values reference: {{ .Values.secrets.dbPassword }}
```

### RBAC in Development

Test with restricted service accounts:

```bash
kubectl create serviceaccount dev-user
kubectl create rolebinding dev-editor \
  --clusterrole=edit \
  --serviceaccount=website:dev-user
```

## Useful Commands

```bash
# ArgoCD
argocd app list
argocd app sync website
argocd app wait website
argocd app logs website
argocd app history website

# Kubernetes
kubectl get events -n website
kubectl top pod -n website
kubectl logs -n website -f deployment/website

# Helm
helm lint apps/website/
helm template website apps/website/
helm values apps/website/
helm diff upgrade website apps/website/ -n website
```

## References

- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/operator-manual/best-practices/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [GitOps Best Practices](https://www.gitops.tech/)
