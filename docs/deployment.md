# Deployment Guide

This guide covers deploying OpenTranscribe backend to Kubernetes.

## Prerequisites

- Kubernetes cluster with NVIDIA GPU Operator installed
- NGINX Ingress Controller
- cert-manager (for TLS certificates)
- DockerHub account with access token
- GitHub repository with secrets configured

## Pre-Deployment Checklist

- [ ] DockerHub username and token configured in GitHub secrets
- [ ] Backend Docker image built and pushed to DockerHub
- [ ] Kubernetes cluster accessible via `kubectl`
- [ ] GPU nodes available and GPU Operator installed
- [ ] Domain DNS configured (if using custom domain)

## Step 1: Configure GitHub Secrets

1. Go to repository → Settings → Secrets and variables → Actions
2. Add secrets:
   - `DOCKERHUB_USERNAME`: Your DockerHub username
   - `DOCKERHUB_TOKEN`: DockerHub Personal Access Token (Read, Write & Delete)

## Step 2: Update Kubernetes Manifests

### Update Deployment Image

Edit `k8s/backend/deployment.yaml`:

```yaml
image: YOUR-DOCKERHUB-USERNAME/opentranscribe-backend:latest
```

Replace `YOUR-DOCKERHUB-USERNAME` with your DockerHub username.

### Update Ingress Hostname (Optional)

Edit `k8s/ingress/ingress.yaml`:

```yaml
- host: stt.beehive-advisors.com
```

Update if using a different domain.

## Step 3: Build and Push Docker Image

### Option A: Using CI/CD (Recommended)

1. Push code to `main` branch
2. GitHub Actions will automatically:
   - Build Docker image
   - Push to DockerHub
   - Update `k8s/backend/deployment.yaml` with new image tag

### Option B: Manual Build

```bash
cd backend
docker build -t YOUR-DOCKERHUB-USERNAME/opentranscribe-backend:latest .
docker push YOUR-DOCKERHUB-USERNAME/opentranscribe-backend:latest
```

## Step 4: Deploy to Kubernetes

```bash
# Apply namespace
kubectl apply -f k8s/namespace.yaml

# Apply backend deployment and service
kubectl apply -f k8s/backend/

# Apply ingress
kubectl apply -f k8s/ingress/
```

## Step 5: Verify Deployment

### Check Pod Status

```bash
kubectl get pods -n opentranscribe
```

Expected output:
```
NAME                                    READY   STATUS    RESTARTS   AGE
opentranscribe-backend-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
```

### Check GPU Allocation

```bash
kubectl describe pod -n opentranscribe <pod-name> | grep -i gpu
```

Expected output:
```
nvidia.com/gpu:  1
```

### Check Service

```bash
kubectl get svc -n opentranscribe
```

Expected output:
```
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
opentranscribe-backend   ClusterIP   10.43.x.x      <none>        80/TCP    1m
```

### Check Ingress

```bash
kubectl get ingress -n opentranscribe
```

Expected output:
```
NAME                    CLASS   HOSTS                          ADDRESS        PORTS     AGE
opentranscribe-backend   nginx   stt.beehive-advisors.com       x.x.x.x        80, 443   1m
```

### View Logs

```bash
kubectl logs -n opentranscribe -l app=opentranscribe-backend -f
```

## Step 6: Test WebSocket Connection

### Using curl (for testing)

```bash
# Test health endpoint
curl https://stt.beehive-advisors.com/health

# WebSocket test requires a WebSocket client
# Use the macOS app or a WebSocket testing tool
```

### Using Python WebSocket Client

```python
import asyncio
import websockets
import json

async def test():
    uri = "wss://stt.beehive-advisors.com/stream"
    async with websockets.connect(uri) as websocket:
        # Send test audio (dummy PCM data)
        test_audio = b'\x00' * 3200  # 0.1s of silence at 16kHz
        await websocket.send(test_audio)
        
        # Receive transcription
        response = await websocket.recv()
        print(json.loads(response))

asyncio.run(test())
```

## Troubleshooting

### Pod Not Starting

**Check pod events**:
```bash
kubectl describe pod -n opentranscribe <pod-name>
```

**Common issues**:
- GPU not available: Check GPU Operator installation
- Image pull error: Verify DockerHub credentials and image name
- Resource limits: Check node resources

### GPU Not Allocated

**Verify GPU Operator**:
```bash
kubectl get nodes -o jsonpath='{.items[*].status.capacity}' | grep gpu
```

**Check GPU labels**:
```bash
kubectl get nodes -o jsonpath='{.items[*].metadata.labels}' | grep nvidia
```

### WebSocket Connection Fails

**Check ingress annotations**:
```bash
kubectl get ingress -n opentranscribe -o yaml | grep websocket
```

**Verify NGINX configuration**:
```bash
kubectl logs -n ingress-nginx <nginx-pod> | grep websocket
```

### Backend Not Responding

**Check backend logs**:
```bash
kubectl logs -n opentranscribe -l app=opentranscribe-backend
```

**Test service directly**:
```bash
kubectl port-forward -n opentranscribe svc/opentranscribe-backend 8000:80
curl http://localhost:8000/health
```

## Updating Deployment

### Update Image Tag

After CI/CD builds a new image:

```bash
# Pull latest changes (includes updated deployment.yaml)
git pull

# Apply updated deployment
kubectl apply -f k8s/backend/deployment.yaml

# Or manually update image tag
kubectl set image deployment/opentranscribe-backend \
  opentranscribe-backend=YOUR-DOCKERHUB-USERNAME/opentranscribe-backend:NEW-TAG \
  -n opentranscribe
```

### Rollback

```bash
kubectl rollout undo deployment/opentranscribe-backend -n opentranscribe
```

## Configuration

### Environment Variables

Edit `k8s/backend/deployment.yaml`:

```yaml
env:
- name: MODEL
  value: "turbo"
- name: DEVICE
  value: "cuda"
- name: COMPUTE_TYPE
  value: "float16"
- name: LOG_LEVEL
  value: "INFO"
```

### Resource Limits

Edit `k8s/backend/deployment.yaml`:

```yaml
resources:
  requests:
    cpu: 500m
    memory: 2Gi
    nvidia.com/gpu: 1
  limits:
    cpu: 4000m
    memory: 8Gi
    nvidia.com/gpu: 1
```

## Cleanup

To remove the deployment:

```bash
kubectl delete -f k8s/ingress/
kubectl delete -f k8s/backend/
kubectl delete -f k8s/namespace.yaml
```

