# Setup Guide

Complete setup instructions for ArgoCD GitOps workflow with k3s.

## Prerequisites

- k3s cluster v1.24+ installed and running
- kubectl v1.24+ configured to access your cluster
- Git repository access configured
- helm v3.0+ (optional, for local testing)

## Step 1: Install ArgoCD

### 1. Create argocd namespace and install

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Wait for ArgoCD components to be ready

```bash
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd
```

### 3. Expose ArgoCD server (choose one method)

**Port Forward (for development):**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Ingress (for production):**

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd
spec:
  rules:
  - host: argocd.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
EOF
```

## Step 2: Configure Repository Access

### For HTTPS repository (with personal token):

1. Create a GitHub personal access token (Settings > Developer settings > Personal access tokens)
2. Create Kubernetes secret:

```bash
kubectl create secret generic argocd-repo-creds \
  -n argocd \
  --from-literal=url=https://github.com/yourusername/dijitle.com \
  --from-literal=password=<YOUR_PERSONAL_TOKEN> \
  --from-literal=username=not-used \
  --dry-run=client -o yaml | kubectl apply -f -
```

### For SSH repository:

1. Generate SSH key (or use existing): `ssh-keygen -t ed25519`
2. Add public key to GitHub repository Deploy Keys
3. Create Kubernetes secret:

```bash
kubectl create secret generic argocd-repo-ssh \
  -n argocd \
  --from-file=sshPrivateKeySecret=/path/to/private/key \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Step 3: Update Repository Configuration

Edit the following files before applying:

### argocd/appproject.yaml

Update the `sourceRepos` with your repository URL pattern

### argocd/applications/website.yaml and api.yaml

Update `spec.source.repoURL` to your repository

Example:

```yaml
spec:
  source:
    repoURL: https://github.com/yourusername/dijitle.com
```

## Step 4: Deploy ArgoCD Applications

### 1. Apply AppProject

```bash
kubectl apply -f argocd/appproject.yaml
```

### 2. Apply root application (this manages all other apps)

```bash
kubectl apply -f argocd/root-application.yaml
```

### Verify deployment:

```bash
# Check applications are created
kubectl get application -n argocd

# Get detailed status
kubectl describe application root -n argocd

# Watch sync progress
kubectl get application -n argocd -w
```

## Step 5: Verify Applications

### Check application status

```bash
kubectl get pods -n website
kubectl get pods -n api
```

### Access applications

Check Ingress configuration and update your hosts file or use port-forward:

```bash
# Website
kubectl port-forward -n website svc/website 8080:80

# API
kubectl port-forward -n api svc/api 8081:80
```

## Access ArgoCD UI

### Get admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### Login via CLI:

```bash
argocd login <ARGOCD_SERVER> --username admin --password <PASSWORD>
```

## Troubleshooting

### ArgoCD server not responding

```bash
# Check if pods are running
kubectl get pods -n argocd

# Check pod logs
kubectl logs -n argocd deployment/argocd-server

# Check resources
kubectl describe pod -n argocd -l app.kubernetes.io/name=argocd-server
```

### Applications stuck in syncing

```bash
# Check application status
kubectl describe application website -n argocd

# Check if namespace was created
kubectl get namespace | grep website

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Repository connection failed

1. Verify repository URL in Application spec
2. Verify credentials in Kubernetes secret
3. Check ArgoCD application controller logs for authentication errors
4. Ensure repository is publicly accessible or secret is properly configured

## Next Steps

1. Configure Ingress for applications (update hostnames in values.yaml)
2. Set up certificate issuer (cert-manager with Let's Encrypt)
3. Configure application-specific secrets
4. Set up monitoring and alerting
5. Document your deployment process

See [ARCHITECTURE.md](ARCHITECTURE.md) for system architecture overview.
