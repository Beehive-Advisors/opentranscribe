# Tech Spec: CI/CD Pipeline Setup for New Repositories

## Overview

This document provides step-by-step instructions for configuring any new repository at Beehive-Advisors to use our self-hosted Kubernetes runners for building Docker images and pushing to DockerHub.

## Architecture

- **GitHub Actions**: Workflow automation
- **ARC (Actions Runner Controller)**: Self-hosted runners on Kubernetes
- **Docker-in-Docker**: Docker builds within Kubernetes pods
- **DockerHub**: Container registry
- **Kubernetes**: Deployment target

## Prerequisites

### Infrastructure (Already Configured)

✅ ARC Controller installed in `actions-runner-system` namespace  
✅ RunnerDeployment (`arc-runner-set`) configured with Docker-in-Docker support  
✅ GitHub App authentication configured  
✅ Kubernetes cluster accessible  

### Per-Repository Requirements

- GitHub repository (organization: `Beehive-Advisors`)
- DockerHub account with access token
- Dockerfile in repository root
- Kubernetes manifests (optional, for deployment)

---

## Step-by-Step Setup Guide

### Step 1: Verify Runner Availability

**Agent (DevOps/Platform Team):**

```bash
# Check runner deployment exists
kubectl get runnerdeployment arc-runner-set -n actions-runner-system

# Verify runner labels
kubectl get runnerdeployment arc-runner-set -n actions-runner-system \
  -o jsonpath='{.spec.template.spec.labels}'

# Expected output: ["self-hosted","arc-runner-set"]
```

**User Action:** None required - runners are shared across all repos in the organization.

---

### Step 2: Configure GitHub Secrets

**User Action Required:**

1. Navigate to your repository: `https://github.com/Beehive-Advisors/YOUR-REPO`
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

#### Required Secrets

| Secret Name | Description | Example |
|------------|-------------|---------|
| `DOCKERHUB_USERNAME` | Your DockerHub username | `giacobbbe` |
| `DOCKERHUB_TOKEN` | DockerHub Personal Access Token | `dckr_pat_...` |

#### Creating DockerHub Token

1. Go to [DockerHub](https://hub.docker.com/) → Account Settings → Security
2. Click **New Access Token**
3. Name: `GitHub Actions - YOUR-REPO`
4. **Permissions**: Select **Read, Write & Delete** (required!)
5. Click **Generate**
6. **Copy immediately** (won't be shown again)
7. Paste into GitHub secret `DOCKERHUB_TOKEN`

**Agent Action:** None - users manage their own DockerHub tokens.

---

### Step 3: Create GitHub Actions Workflow

**User Action Required:**

Create `.github/workflows/docker-build.yml` in your repository:

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: arc-runner-set  # Must match runner label
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to DockerHub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}
        logout: false
    
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        push: ${{ github.event_name == 'push' }}
        tags: |
          ${{ secrets.DOCKERHUB_USERNAME }}/YOUR-IMAGE-NAME:latest
          ${{ secrets.DOCKERHUB_USERNAME }}/YOUR-IMAGE-NAME:${{ github.sha }}
    
    - name: Update Kubernetes manifests
      if: github.event_name == 'push' && github.ref == 'refs/heads/main'
      run: |
        # Update image tag in Kubernetes manifests
        sed -i.bak "s|image:.*YOUR-IMAGE-NAME.*|image: ${{ secrets.DOCKERHUB_USERNAME }}/YOUR-IMAGE-NAME:${{ github.sha }}|g" k8s/deployment.yaml
        rm -f k8s/deployment.yaml.bak
        echo "Updated k8s/deployment.yaml with image tag ${{ github.sha }}"
        echo "Manifest updated. Commit and push manually or configure workflow permissions."
```

**Customization Points:**

- Replace `YOUR-IMAGE-NAME` with your application name (e.g., `arc-app`, `api-service`, `web-app`)
- Adjust `branches: [ main ]` if using different branch names
- Modify Kubernetes manifest path if different from `k8s/deployment.yaml`

**Agent Action:** None - users create their own workflows.

---

### Step 4: Create Dockerfile

**User Action Required:**

Create `Dockerfile` in repository root:

```dockerfile
FROM alpine:latest

# Your application setup
WORKDIR /app
COPY . .

# Build/install steps
# RUN npm install  # Example for Node.js
# RUN pip install -r requirements.txt  # Example for Python

# Expose port
EXPOSE 8080

# Start command
CMD ["echo", "Hello from container"]
```

**Customization:** Adapt to your application stack (Node.js, Python, Go, Java, etc.)

**Agent Action:** None - users create their own Dockerfiles.

---

### Step 5: Create Kubernetes Manifests (Optional)

**User Action Required:**

Create `k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: YOUR-APP-NAME
  labels:
    app: YOUR-APP-NAME
spec:
  replicas: 1
  selector:
    matchLabels:
      app: YOUR-APP-NAME
  template:
    metadata:
      labels:
        app: YOUR-APP-NAME
    spec:
      containers:
      - name: YOUR-APP-NAME
        image: YOUR-DOCKERHUB-USERNAME/YOUR-IMAGE-NAME:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
```

Create `k8s/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: YOUR-APP-NAME
  labels:
    app: YOUR-APP-NAME
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: YOUR-APP-NAME
```

**Customization:**

- Replace `YOUR-APP-NAME` with your application name
- Replace `YOUR-DOCKERHUB-USERNAME` with your DockerHub username
- Replace `YOUR-IMAGE-NAME` with your image name
- Adjust ports, resources, and service type as needed

**Agent Action:** None - users create their own manifests.

---

### Step 6: Verify Setup

**User Action:**

1. Commit and push workflow file:
   ```bash
   git add .github/workflows/docker-build.yml Dockerfile
   git commit -m "Add CI/CD pipeline"
   git push origin main
   ```

2. Check GitHub Actions tab:
   - Go to repository → **Actions** tab
   - Verify workflow appears and runs
   - Check that it uses runner `arc-runner-set`

3. Verify DockerHub:
   - Check DockerHub repository: `https://hub.docker.com/r/YOUR-USERNAME/YOUR-IMAGE-NAME`
   - Verify images appear with `latest` and commit SHA tags

**Agent Action:**

```bash
# Monitor runner activity
kubectl get pods -n actions-runner-system -l runner-deployment-name=arc-runner-set

# Check runner logs
kubectl logs -n actions-runner-system -l runner-deployment-name=arc-runner-set --tail=50
```

---

## Quick Start Checklist

### For Users (Repository Owners)

- [ ] Create `.github/workflows/docker-build.yml` (copy template above)
- [ ] Replace `YOUR-IMAGE-NAME` in workflow file
- [ ] Create `Dockerfile` in repository root
- [ ] Add `DOCKERHUB_USERNAME` secret to GitHub repository
- [ ] Create DockerHub token with Read, Write & Delete permissions
- [ ] Add `DOCKERHUB_TOKEN` secret to GitHub repository
- [ ] Create `k8s/` directory with manifests (optional)
- [ ] Update image name in Kubernetes manifests
- [ ] Commit and push to trigger workflow
- [ ] Verify workflow runs successfully
- [ ] Verify image appears on DockerHub

### For Agents (DevOps/Platform Team)

- [ ] Verify ARC controller is running
- [ ] Verify runner deployment exists: `arc-runner-set`
- [ ] Verify runner labels match: `["self-hosted","arc-runner-set"]`
- [ ] Monitor runner capacity (min: 0, max: 10)
- [ ] Check runner logs for errors
- [ ] Verify GitHub App authentication is working

---

## Troubleshooting

### Workflow Not Picking Up Runner

**Symptoms:** Workflow shows "Waiting for runner" or uses GitHub-hosted runner

**Check:**
```bash
# Verify runner label matches workflow
kubectl get runnerdeployment arc-runner-set -n actions-runner-system \
  -o jsonpath='{.spec.template.spec.labels}'
# Should output: ["self-hosted","arc-runner-set"]

# Verify workflow uses correct label
# In .github/workflows/docker-build.yml, check:
# runs-on: arc-runner-set
```

**Fix:** Ensure workflow file has `runs-on: arc-runner-set` (exact match)

---

### DockerHub Authentication Fails

**Symptoms:** Error: "401 Unauthorized: access token has insufficient scopes"

**Check:**
- DockerHub token has **Read, Write & Delete** permissions (not just Read)
- Token is not expired
- Secret name is exactly `DOCKERHUB_TOKEN` (case-sensitive)
- Username secret is exactly `DOCKERHUB_USERNAME`

**Fix:** Create new DockerHub token with proper permissions and update secret

---

### Docker Build Fails

**Symptoms:** Build errors in workflow logs

**Check:**
```bash
# Verify Docker is working in runner
kubectl exec -n actions-runner-system <runner-pod> -- docker --version
kubectl exec -n actions-runner-system <runner-pod> -- docker ps
```

**Fix:** 
- Check Dockerfile syntax
- Verify build context is correct
- Check for missing dependencies in Dockerfile

---

### Runner Pod Not Starting

**Symptoms:** Runner pod stuck in Pending or CrashLoopBackOff

**Check:**
```bash
# Describe pod for errors
kubectl describe pod -n actions-runner-system <pod-name>

# Check resource constraints
kubectl top nodes
kubectl top pods -n actions-runner-system
```

**Fix:**
- Check cluster resources
- Verify runner deployment configuration
- Check for node selectors or taints

---

## Advanced Configuration

### Custom Runner Labels

If you need repository-specific runners:

**Agent Action:**

```bash
# Create new runner deployment with custom label
kubectl apply -f - <<EOF
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: custom-runner-set
  namespace: actions-runner-system
spec:
  replicas: 1
  template:
    spec:
      organization: Beehive-Advisors
      labels:
      - self-hosted
      - custom-runner-set  # Custom label
      dockerEnabled: true
      dockerdWithinRunnerContainer: true
      image: summerwind/actions-runner-dind:latest
      dockerdContainerResources:
        limits:
          cpu: "4"
          memory: "2Gi"
        requests:
          cpu: "1"
          memory: "1Gi"
EOF
```

**User Action:** Update workflow to use custom label:
```yaml
runs-on: custom-runner-set
```

### Resource Limits

**Agent Action:** Adjust runner resources in `runner-deployment-dind.yaml`:

```yaml
dockerdContainerResources:
  limits:
    cpu: "4"      # Current limit (can increase further for larger builds)
    memory: "2Gi"
  requests:
    cpu: "1"
    memory: "1Gi"
```

### Multiple Environments

**User Action:** Create separate workflows for different environments:

`.github/workflows/docker-build-staging.yml`:
```yaml
# Same as docker-build.yml but with staging tags
tags: |
  ${{ secrets.DOCKERHUB_USERNAME }}/YOUR-IMAGE-NAME:staging
  ${{ secrets.DOCKERHUB_USERNAME }}/YOUR-IMAGE-NAME:${{ github.sha }}
```

---

## Support and Maintenance

### Monitoring

**Agent Responsibilities:**

- Monitor runner capacity and scaling
- Check ARC controller health
- Review runner logs for errors
- Update ARC controller and runner images periodically

**Commands:**
```bash
# Check runner status
kubectl get runners -n actions-runner-system

# Check runner deployment
kubectl get runnerdeployment -n actions-runner-system

# Monitor pod creation
kubectl get pods -n actions-runner-system -w
```

### Updates

**ARC Controller Updates:**
- Check for updates: `helm repo update actions-runner-controller`
- Review changelog before upgrading
- Test in non-production first

**Runner Image Updates:**
- Update `summerwind/actions-runner-dind:latest` periodically
- Consider pinning to specific versions for stability

---

## Reference

### Key Files

- **Workflow Template**: `.github/workflows/docker-build.yml`
- **Runner Config**: `runner-deployment-dind.yaml` (infrastructure)
- **Kubernetes Manifests**: `k8s/deployment.yaml`, `k8s/service.yaml`

### Key Commands

```bash
# Check runners
kubectl get runners -n actions-runner-system

# Check runner pods
kubectl get pods -n actions-runner-system -l runner-deployment-name=arc-runner-set

# View runner logs
kubectl logs -n actions-runner-system -l runner-deployment-name=arc-runner-set --tail=100

# Check runner deployment
kubectl get runnerdeployment arc-runner-set -n actions-runner-system -o yaml
```

### Important URLs

- GitHub Repository: `https://github.com/Beehive-Advisors/YOUR-REPO`
- GitHub Actions: `https://github.com/Beehive-Advisors/YOUR-REPO/actions`
- DockerHub: `https://hub.docker.com/r/YOUR-USERNAME/YOUR-IMAGE-NAME`
- DockerHub Token Creation: `https://hub.docker.com/settings/security`

---

## Version History

- **v1.0** (2025-11-13): Initial tech spec based on ARC CI/CD implementation

---

## Questions or Issues?

Contact the DevOps/Platform team for:
- Runner capacity issues
- ARC controller problems
- Infrastructure changes
- Custom runner requirements

Contact repository owners for:
- Workflow configuration
- Dockerfile issues
- Application-specific build problems

