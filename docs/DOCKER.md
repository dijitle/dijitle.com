# Docker Build Documentation

## Overview

This repository uses multi-stage Docker builds to create optimized container images for both the website and API applications. GitHub Actions automatically builds and pushes images to GitHub Container Registry (GHCR) on push to main/develop branches.

## Docker Images

### Website Image
- **Dockerfile**: `apps/website/Dockerfile`
- **Base Images**:
  - Builder: `node:18-alpine` (for build step)
  - Runtime: `nginx:1.25-alpine` (lightweight web server)
- **Size**: ~50MB (optimized with multi-stage build)
- **Exposed Port**: 80

### API Image
- **Dockerfile**: `apps/api/Dockerfile`
- **Base Images**:
  - Builder: `python:3.11-slim` (for build step)
  - Runtime: `python:3.11-slim` (lightweight runtime)
- **Size**: ~150MB (optimized with multi-stage build)
- **Exposed Port**: 8000

## Multi-Stage Build Strategy

### Website Build Process

1. **Builder Stage**:
   - Uses Node.js 18 alpine image
   - Installs npm dependencies
   - Builds the application (webpack)
   - Only the built artifacts are carried forward

2. **Runtime Stage**:
   - Uses lightweight nginx alpine image
   - Copies optimized nginx configuration
   - Copies built artifacts from builder
   - Runs nginx as web server

### API Build Process

1. **Builder Stage**:
   - Uses Python 3.11-slim image
   - Installs build tools (gcc, headers)
   - Creates virtual environment
   - Installs Python dependencies
   - Only virtual environment is carried forward

2. **Runtime Stage**:
   - Uses lightweight Python 3.11-slim image
   - Creates non-root user for security
   - Copies virtual environment from builder
   - Runs API with uvicorn

## GitHub Actions Workflow

### Workflow File
- **Location**: `.github/workflows/docker-build.yml`
- **Triggers**:
  - `push` to main/develop branches (when `apps/` changes)
  - `pull_request` to main/develop branches
  - Manual workflow dispatch

### Build Jobs

#### 1. build-website
- Checks out code
- Sets up Docker Buildx for advanced features
- Authenticates with GitHub Container Registry
- Extracts image metadata and tags
- Builds multi-stage Docker image
- Pushes to registry on merge

#### 2. build-api
- Same process as website build
- Separate job for parallelization

#### 3. security-scan
- Runs Trivy vulnerability scanner on images
- Uploads results to GitHub Security tab
- Only runs on main branch

### Image Tags

Images are tagged with:
- `latest` - Latest on main branch
- Branch name (e.g., `develop`, `main`)
- Git SHA (e.g., `main-abc123def`)
- Semantic version tags (when using Git tags)

Example: `ghcr.io/yourusername/dijitle.com/website:latest`

## Building Locally

### Build Website Image
```bash
cd apps/website
docker build -t dijitle-website:latest .
```

### Build API Image
```bash
cd apps/api
docker build -t dijitle-api:latest .
```

### Run Website
```bash
docker run -p 8080:80 dijitle-website:latest
# Access at http://localhost:8080
```

### Run API
```bash
docker run -p 8000:8000 dijitle-api:latest
# Access at http://localhost:8000
```

## Image Inspection

### View image layers
```bash
docker inspect dijitle-website:latest
docker image history dijitle-website:latest
```

### Check size reduction
```bash
# Multi-stage build reduces final image size significantly
docker images | grep dijitle
```

### Run with environment variables
```bash
docker run -e LOG_LEVEL=DEBUG -p 8000:8000 dijitle-api:latest
```

## Kubernetes Deployment

Update the Helm values to use the built images:

```yaml
# apps/website/values.yaml
image:
  repository: ghcr.io/yourusername/dijitle.com/website
  tag: "latest"  # or specific SHA/version

# apps/api/values.yaml
image:
  repository: ghcr.io/yourusername/dijitle.com/api
  tag: "latest"
```

## Container Registry Configuration

### GitHub Container Registry (GHCR)

Automatic authentication via `${{ secrets.GITHUB_TOKEN }}` in workflows.

### Pushing to Other Registries

To push to Docker Hub or other registries, add credentials in repository secrets:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

Update `.github/workflows/docker-build.yml` to login to additional registries:

```yaml
- name: Log in to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

## Best Practices Implemented

✅ **Multi-stage builds** - Reduces final image size  
✅ **Alpine base images** - Minimal and secure base  
✅ **Non-root user** - API runs as unprivileged user  
✅ **Health checks** - Both images include HEALTHCHECK  
✅ **.dockerignore** - Excludes unnecessary files  
✅ **Cache layers** - Uses GitHub Actions cache for faster builds  
✅ **Security scanning** - Trivy scans for vulnerabilities  
✅ **Metadata tags** - Semantic versioning and git SHA tracking  

## Troubleshooting

### Build fails in GitHub Actions
1. Check workflow logs in Actions tab
2. Verify repository has write access to packages
3. Check for Docker syntax errors locally first

### Images not pushing to registry
1. Confirm GITHUB_TOKEN has `packages:write` permission
2. Check repository Settings > Actions > General > Workflow permissions
3. Verify branch protection rules allow Actions

### Image too large
1. Review Dockerfile for unnecessary dependencies
2. Use `.dockerignore` to exclude files
3. Consider removing debug tools in runtime stage

## References

- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [GitHub Actions Docker Documentation](https://github.com/docker/build-push-action)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Trivy Vulnerability Scanner](https://aquasecurity.github.io/trivy/)
