# Architecture

Overview of the ArgoCD GitOps architecture for k3s cluster.

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  argocd/     │  │  apps/       │  │  docs/           │  │
│  ├──────────────┤  ├──────────────┤  ├──────────────────┤  │
│  │ appproject   │  │ website/     │  │ SETUP.md         │  │
│  │ root-app     │  │ api/         │  │ ARCHITECTURE.md  │  │
│  │ applications │  │              │  │ DEVELOPMENT.md   │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
          ▲
          │ Watches for changes (polling/webhook)
          │
┌─────────────────────────────────────────────────────────────┐
│                    k3s Kubernetes Cluster                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              ArgoCD Namespace                        │   │
│  │  ┌────────────┐  ┌──────────────┐  ┌────────────┐   │   │
│  │  │API Server  │  │Application   │  │Repository  │   │   │
│  │  │            │  │Controller    │  │Server      │   │   │
│  │  └────────────┘  └──────────────┘  └────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                        ▼                                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Kubernetes API Server                     │ │
│  └────────────────────────────────────────────────────────┘ │
│    ▲                           ▲                           │
│    │ Creates/Manages           │ Monitors                  │
│    ▼                           ▼                           │
│  ┌─────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │  website    │  │  api             │  │  other       │ │
│  │  namespace  │  │  namespace       │  │  namespaces  │ │
│  │             │  │                  │  │              │ │
│  │ ┌─────────┐ │  │ ┌──────────────┐ │  │              │ │
│  │ │Deployment│ │  │ │ Deployment   │ │  │              │ │
│  │ │Service  │ │  │ │ Service      │ │  │              │ │
│  │ │Ingress  │ │  │ │ Ingress      │ │  │              │ │
│  │ └─────────┘ │  │ │ HPA          │ │  │              │ │
│  │             │  │ └──────────────┘ │  │              │ │
│  └─────────────┘  └──────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Components

### GitHub Repository

The single source of truth for infrastructure and application configuration.

- **argocd/** - ArgoCD configuration
  - `appproject.yaml` - Defines project and permissions
  - `root-application.yaml` - Root application managing other apps
  - `applications/` - Individual application definitions

- **apps/** - Helm charts for applications
  - Each application in its own directory
  - Contains Chart.yaml, values.yaml, and templates/

- **docs/** - Documentation

### ArgoCD

Watches the GitHub repository and automatically syncs changes to the cluster.

**ArgoCD Components:**

- **API Server** - REST API and web UI
- **Application Controller** - Monitors applications and performs syncing
- **Repository Server** - Clones and manages repository
- **Redis** - Caching layer (optional)

**Key Features:**

- Continuous deployment from Git
- Declarative configuration
- Automated sync
- Self-healing (corrects drift)
- Multi-environment support
- RBAC integration

### Applications

Kubernetes manifests deployed via Helm charts.

**website** - Frontend application

- 2 replicas (fixed)
- nginx container
- Service and Ingress
- No autoscaling by default

**api** - Backend API

- 2-10 replicas (with HPA)
- Python 3.11 container
- Service and Ingress
- Horizontal Pod Autoscaler enabled

## GitOps Workflow

### Standard Deployment Flow

```
1. Developer commits changes to Git repo
   └─> Update values.yaml or manifests
       └─> Git push to main branch

2. ArgoCD detects changes
   └─> Repository Server fetches latest
       └─> Compares desired vs actual state

3. ArgoCD syncs to cluster
   └─> Application Controller reconciles state
       └─> kubectl apply equivalent operations

4. Kubernetes resources updated
   └─> Deployments roll out new versions
       └─> Services and Ingresses configured
           └─> Applications accessible
```

### Rollback Process

```
ArgoCD automatically tracks git history
└─> Can rollback to any previous commit
    └─> Simple revision selection in UI
        └─> Automatic sync to cluster
```

## File Structure Details

### Helm Chart Structure

```
apps/website/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
└── templates/
    ├── _helpers.tpl        # Template helper functions
    ├── deployment.yaml     # Kubernetes Deployment
    └── service.yaml        # Kubernetes Service
```

### Application Definition

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: website
  namespace: argocd
spec:
  project: k3s-apps # References AppProject
  source:
    repoURL: <git-repo> # Source repository
    targetRevision: HEAD # Branch/tag/commit
    path: apps/website # Path in repo
  destination:
    server: https://kubernetes.default.svc # Target cluster
    namespace: website # Target namespace
  syncPolicy:
    automated:
      prune: true # Remove deleted resources
      selfHeal: true # Fix drift
    syncOptions:
      - CreateNamespace=true # Create namespace if missing
```

## Deployment Namespaces

- `argocd` - ArgoCD system components
- `website` - Website application
- `api` - API application
- `kube-system` - Kubernetes system pods
- `default` - Default namespace

## Network Architecture

### Ingress Configuration

Applications exposed via Kubernetes Ingress controller (nginx):

- **website**: example.com -> website service:80
- **api**: api.example.com -> api service:80

### DNS Resolution

Applications accessible via configured hostnames:

- Update `/etc/hosts` for local dev
- Configure DNS records for production
- Ingress controller routes traffic

## Security Considerations

### RBAC

AppProject restricts which resources can be deployed:

- Blacklist cluster-scoped resources (Namespace, ResourceQuota)
- Allow deployment only within designated namespaces
- Restrict to single source repository

### Repository Access

- SSH keys or personal tokens for private repositories
- Kubernetes secrets store credentials
- ArgoCD securely manages keys

### Resource Limits

Each application defines:

- CPU requests/limits
- Memory requests/limits
- Prevents resource exhaustion

## Scaling Strategy

### Horizontal Pod Autoscaling (HPA)

**api** application configured with HPA:

- Min replicas: 2
- Max replicas: 10
- CPU target: 80%

**website** application:

- Fixed 2 replicas
- No autoscaling by default

### Resource Distribution

Requests ensure minimum resources:

- website: 100m CPU, 128Mi memory per pod
- api: 250m CPU, 256Mi memory per pod

## High Availability

- Multiple application replicas
- Service endpoints distribute traffic
- Automatic failed pod replacement
- Self-healing corrects drift

## Monitoring and Observability

Recommended additions:

- Prometheus for metrics collection
- Grafana for visualization
- ELK stack for logging
- ArgoCD notifications for sync status

See [DEVELOPMENT.md](DEVELOPMENT.md) for observability setup.

## Future Enhancements

- Multiple cluster support (production/staging)
- Blue-green deployments
- Canary releases
- Cross-environment promotion
- Automated testing integration
- Secret management (sealed-secrets, external-secrets)
