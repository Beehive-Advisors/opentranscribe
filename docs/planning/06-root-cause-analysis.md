# Root Cause Analysis: ImagePullBackOff Error

## Problem Summary

Kubernetes pod `opentranscribe-backend-8678f97998-6dsr2` is in `ImagePullBackOff` state with error:
```
Failed to pull image "giacobbbe/opentranscribe-backend:latest": 
failed to pull and unpack image "docker.io/giacobbbe/opentranscribe-backend:latest": 
failed to resolve reference "docker.io/giacobbbe/opentranscribe-backend:latest": 
pull access denied, repository does not exist or may require authorization: 
server message: insufficient_scope: authorization failed
```

## Root Cause

**The Docker image does not exist in DockerHub.**

### Evidence

1. **DockerHub API Check**: 
   ```bash
   curl https://hub.docker.com/v2/repositories/giacobbbe/opentranscribe-backend/
   # Returns: {"message":"object not found","errinfo":{}}
   ```

2. **Pod Events**:
   - Error: "repository does not exist"
   - Status: `ImagePullBackOff` → `ErrImagePull`

3. **Git History**:
   - Code was pushed to `main` branch (commit `5bfcaa2`)
   - GitHub Actions workflow should have triggered on push
   - Workflow file exists: `.github/workflows/backend-build.yml`

## Why Image Doesn't Exist

The GitHub Actions CI/CD workflow that builds and pushes the Docker image has either:
1. **Not run yet** - Workflow may still be queued/running
2. **Failed** - Workflow may have encountered an error
3. **Not triggered** - Workflow may not have been triggered (unlikely, since code was pushed)
4. **Secrets not configured** - `DOCKERHUB_USERNAME` or `DOCKERHUB_TOKEN` may be missing

## Investigation Steps

### 1. Check GitHub Actions Workflow Status

```bash
# Check workflow runs (requires GitHub CLI or web UI)
# Web UI: https://github.com/jacobcoccari/opentranscribe/actions
```

### 2. Verify ARC Runner Availability

```bash
# Check runner deployment
kubectl get runnerdeployment arc-runner-set -n actions-runner-system

# Check runner pods
kubectl get pods -n actions-runner-system -l runner-deployment-name=arc-runner-set

# Check runner logs
kubectl logs -n actions-runner-system -l runner-deployment-name=arc-runner-set --tail=50
```

### 3. Verify GitHub Secrets

Check that these secrets exist in GitHub repository:
- `DOCKERHUB_USERNAME` (should be `giacobbbe`)
- `DOCKERHUB_TOKEN` (DockerHub Personal Access Token)

**Location**: Repository → Settings → Secrets and variables → Actions

### 4. Check Workflow Configuration

The workflow file `.github/workflows/backend-build.yml` is configured to:
- Trigger on push to `main` branch ✅
- Use `arc-runner-set` runner ✅
- Build from `./backend` directory ✅
- Push to `${{ secrets.DOCKERHUB_USERNAME }}/opentranscribe-backend:latest` ✅

## Solutions

### Option 1: Wait for CI/CD (Recommended)

If GitHub Actions workflow is running:
1. Monitor workflow: https://github.com/jacobcoccari/opentranscribe/actions
2. Wait for workflow to complete
3. Verify image exists: https://hub.docker.com/r/giacobbbe/opentranscribe-backend
4. Pod will automatically pull image once available

### Option 2: Trigger Workflow Manually

If workflow hasn't run:
1. Make a small commit to trigger workflow:
   ```bash
   git commit --allow-empty -m "Trigger CI/CD build"
   git push origin main
   ```

### Option 3: Build and Push Locally (If Docker Available)

If you have Docker installed locally:
```bash
cd backend
docker build -t giacobbbe/opentranscribe-backend:latest .
docker login
docker push giacobbbe/opentranscribe-backend:latest
```

### Option 4: Check and Fix Workflow Issues

If workflow failed:
1. Check workflow logs in GitHub Actions
2. Verify secrets are configured correctly
3. Check ARC runner is available and healthy
4. Fix any errors in workflow logs

## Verification

Once image is available, verify:

```bash
# Check pod status (should change to Running)
kubectl get pods -n opentranscribe

# Check pod logs
kubectl logs -n opentranscribe -l app=opentranscribe-backend -f

# Verify image was pulled
kubectl describe pod -n opentranscribe -l app=opentranscribe-backend | grep Image
```

## Prevention

To prevent this in the future:
1. **Monitor CI/CD**: Set up notifications for workflow failures
2. **Pre-deployment checks**: Verify image exists before deploying
3. **Health checks**: Add pre-flight checks in deployment scripts
4. **Documentation**: Document the CI/CD process clearly

## Current Status

- ✅ Kubernetes deployment configured correctly
- ✅ Ingress configured correctly
- ✅ Service configured correctly
- ❌ Docker image does not exist
- ⏳ Waiting for CI/CD to build and push image

## Next Steps

1. **Immediate**: Check GitHub Actions workflow status
2. **If workflow not running**: Trigger manually or investigate why
3. **If workflow failed**: Review logs and fix issues
4. **Once image exists**: Pod will automatically start

