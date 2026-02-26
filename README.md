# Dijitle.com - ArgoCD GitOps Repository

Multi-application Kubernetes deployment repository using ArgoCD and Helm charts for k3s cluster.

## 📁 Repository Structure

`├── .github/
│   └── workflows/
│       └── docker-build.yml       # GitHub Actions for Docker builds
├── apps/                          # Helm charts and Dockerfiles
│   ├── website/                   # Website application
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   ├── .dockerignore
│   │   ├── package.json
│   │   └── templates/
│   └── api/                       # API application
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── Dockerfile
│       ├── .dockerignore
│       ├── requirements.txt
│       ├── main.py
│       └── templates/
├── argocd/                        # ArgoCD configuration
│   ├── appproject.yaml            # AppProject definition
│   ├── root-application.yaml      # Root app that manages other apps
│   └── applications/              # Individual app definitions
│       ├── website.yaml
│       └── api.yaml
├── docs/                          # Documentation
│   ├── SETUP.md
│   ├── ARCHITECTURE.md
│   ├── DEVELOPMENT.md
│   └── DOCKER.md
└── LICENSE`

## 🚀 Quick Start

### Prerequisites

- k3s cluster running
- kubectl configured to access your cluster
- ArgoCD installed in your cluster

### Install ArgoCD

````bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
``

### Deploy Applications

Apply the AppProject and root application:

```bash
kubectl apply -f argocd/appproject.yaml
kubectl apply -f argocd/root-application.yaml
``

This will automatically sync and deploy all applications defined in rgocd/applications/.

### Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
# Default username: admin
# Get initial password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
``

## 📦 Applications

### Website
- **Path**: apps/website/
- **Namespace**: website
- **Image**: nginx
- **Replicas**: 2
- **Exposed**: via Ingress (example.com)

### API
- **Path**: apps/api/
- **Namespace**: api
- **Image**: python:3.11-slim
- **Replicas**: 2 (with autoscaling up to 10)
- **Exposed**: via Ingress (api.example.com)

## 🔧 Configuration

### Update Application Source

Edit argocd/applications/*.yaml and argocd/appproject.yaml to update:
- GitHub repository URL (replace yourusername)
- Target branch/revision
- Namespaces
- Resource policies

### Customize Helm Values

Update apps/<app-name>/values.yaml to customize:
- Image versions
- Resource limits
- Replica counts
- Ingress configuration
- Environment variables

## 📝 GitOps Workflow

1. **Make changes** to Helm values or application manifests locally
2. **Commit and push** to your repository
3. **ArgoCD detects** the changes (automatically or on sync)
4. **Applications sync** to the cluster

Changes in this repository automatically propagate to your k3s cluster via ArgoCD's continuous synchronization.

## 🔐 ArgoCD Configuration

- **Auto-sync**: Enabled (automatic deployment on repo changes)
- **Prune**: Enabled (removes resources deleted from repo)
- **Self-heal**: Enabled (fixes manual cluster changes)

## 📚 Additional Documentation

- [Setup Guide](docs/SETUP.md) - Detailed installation instructions
- [Architecture](docs/ARCHITECTURE.md) - System architecture overview
- [Development](docs/DEVELOPMENT.md) - Development workflow
- [Docker Build](docs/DOCKER.md) - Docker image building and GitHub Actions CI/CD

## 🛠️ Common Tasks

### Add a New Application

1. Create a new directory under apps/: mkdir -p apps/myapp/templates
2. Create Chart.yaml and values.yaml
3. Create Helm templates in templates/
4. Create ArgoCD Application: argocd/applications/myapp.yaml
5. Push to repository - ArgoCD will automatically deploy

### Update Application Version

1. Edit the image tag in apps/<app-name>/values.yaml
2. Commit and push
3. ArgoCD syncs automatically (or trigger manual sync)

### Rollback to Previous Version

In ArgoCD UI:
1. Go to application
2. Click "History"
3. Select previous revision and click "Rollback"

## 🐛 Troubleshooting

### Application Not Syncing

1. Check ArgoCD logs: kubectl logs -n argocd deployment/argocd-application-controller
2. Verify repository access is configured
3. Check AppProject permissions
4. Review Application spec for errors

### Check Application Status

```bash
# List all applications
kubectl get application -n argocd

# Get detailed status
kubectl describe application website -n argocd

# View sync history
kubectl get application website -n argocd -o jsonpath='{.status.operationState}'
``

## 📖 Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [k3s Documentation](https://docs.k3s.io/)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
````
