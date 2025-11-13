# Quick Fix: Trigger Docker Image Build

## What We Did

1. **Committed deployment change**: Updated `k8s/backend/deployment.yaml` with DockerHub username `giacobbbe`
2. **Pushed to trigger workflow**: Pushed to `main` branch to trigger GitHub Actions CI/CD
3. **Workflow will build**: GitHub Actions will now build and push the Docker image

## What Happens Next

1. **GitHub Actions Workflow Runs**:
   - Triggers on push to `main` branch
   - Uses `arc-runner-set` runner (already available)
   - Builds Docker image from `./backend/Dockerfile`
   - Pushes to DockerHub: `giacobbbe/opentranscribe-backend:latest` and `:$GITHUB_SHA`

2. **Kubernetes Pod Updates**:
   - Once image is pushed, pod will automatically retry pulling
   - Pod status will change from `ImagePullBackOff` → `Running`
   - Backend will start and be available at `wss://stt.beehive-advisors.com/stream`

## Monitor Progress

### Check Workflow Status
```bash
# Visit GitHub Actions (or use GitHub CLI)
# https://github.com/jacobcoccari/opentranscribe/actions
```

### Watch Pod Status
```bash
# Watch pod status (will change to Running once image is available)
kubectl get pods -n opentranscribe -w

# Check pod events
kubectl describe pod -n opentranscribe -l app=opentranscribe-backend
```

### Check Image Availability
```bash
# Once workflow completes, verify image exists
curl -s "https://hub.docker.com/v2/repositories/giacobbbe/opentranscribe-backend/" | grep -q "name" && echo "Image exists!" || echo "Image not found yet"
```

### Check Pod Logs (Once Running)
```bash
# Once pod is Running, check logs
kubectl logs -n opentranscribe -l app=opentranscribe-backend -f
```

## Expected Timeline

- **Workflow start**: ~30 seconds after push
- **Docker build**: ~5-10 minutes (CUDA base image + dependencies)
- **Image push**: ~1 minute
- **Pod pull & start**: ~30 seconds after image is available
- **Total**: ~7-12 minutes

## Troubleshooting

### If Workflow Doesn't Start
- Check GitHub repository settings
- Verify workflow file exists: `.github/workflows/backend-build.yml`
- Check branch name matches: `main`

### If Workflow Fails
- Check workflow logs in GitHub Actions
- Verify secrets: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`
- Check runner availability: `kubectl get pods -n actions-runner-system`

### If Pod Still Shows ImagePullBackOff
- Wait a few more minutes for image to propagate
- Check DockerHub: https://hub.docker.com/r/giacobbbe/opentranscribe-backend
- Verify image tag matches deployment: `giacobbbe/opentranscribe-backend:latest`

## Alternative: Manual Build (If Needed)

If CI/CD doesn't work, you can build locally (if Docker is available):

```bash
cd backend
docker build -t giacobbbe/opentranscribe-backend:latest .
docker login
docker push giacobbbe/opentranscribe-backend:latest
```

Then the pod will automatically pull the image.

