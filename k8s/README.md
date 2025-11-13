# Kubernetes Deployment

This directory contains Kubernetes manifests for deploying OpenTranscribe backend.

## Prerequisites

- Kubernetes cluster with NVIDIA GPU Operator installed
- NGINX Ingress Controller
- cert-manager (for TLS certificates)
- DockerHub credentials configured

## Files

- `namespace.yaml`: Namespace definition
- `backend/deployment.yaml`: Backend deployment with GPU support
- `backend/service.yaml`: ClusterIP service
- `ingress/ingress.yaml`: NGINX ingress with WebSocket support

## Deployment

### Before deploying

1. Update `backend/deployment.yaml`:
   - Replace `YOUR-DOCKERHUB-USERNAME` with your DockerHub username
   - Update image tag if needed (default: `latest`)

2. Update `ingress/ingress.yaml`:
   - Update hostname if different from `stt.beehive-advisors.com`

### Deploy

```bash
# Apply namespace
kubectl apply -f namespace.yaml

# Apply backend
kubectl apply -f backend/

# Apply ingress
kubectl apply -f ingress/
```

### Verify

```bash
# Check deployment
kubectl get pods -n opentranscribe

# Check service
kubectl get svc -n opentranscribe

# Check ingress
kubectl get ingress -n opentranscribe

# View logs
kubectl logs -n opentranscribe -l app=opentranscribe-backend -f

# Check GPU allocation
kubectl describe pod -n opentranscribe <pod-name> | grep -i gpu
```

## WebSocket Endpoint

After deployment, the WebSocket endpoint will be available at:
- `wss://stt.beehive-advisors.com/stream`

## Configuration

Environment variables can be modified in `backend/deployment.yaml`:
- `MODEL`: Whisper model (default: "turbo")
- `DEVICE`: Device (default: "cuda")
- `COMPUTE_TYPE`: Compute type (default: "float16")
- `LOG_LEVEL`: Logging level (default: "INFO")

