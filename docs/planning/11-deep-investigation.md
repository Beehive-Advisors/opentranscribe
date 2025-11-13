# Deep Investigation: Runner Not Picking Up Jobs

## Findings

### ✅ Infrastructure Status
- **ARC Controller**: Running and healthy
- **Runner Pod**: Running and listening (`2025-11-13 08:39:51Z: Listening for Jobs`)
- **Runner Registration**: Successfully registered to `Beehive-Advisors` organization
- **Runner Labels**: `["self-hosted","arc-runner-set"]` ✅ matches workflow
- **Registration Token**: Valid and updated

### 🔍 Key Observations

1. **Runner Registration**: 
   - Organization: `Beehive-Advisors` ✅
   - Repository: `""` (empty - correct for org-level runner)
   - Labels: `["self-hosted","arc-runner-set"]` ✅

2. **Controller Logs**:
   - No errors in ARC controller
   - Runner pod created successfully
   - Registration token updated successfully
   - Runner appears registered and running

3. **Runner Logs**:
   - Connected to GitHub ✅
   - Listening for jobs ✅
   - No job requests received

### ❌ Root Cause Hypothesis

The runner is **correctly configured and listening**, but **GitHub is not routing jobs to it**. This indicates:

1. **GitHub Actions may be disabled** for the repository after transfer
2. **GitHub App installation** may need repository access refresh
3. **GitHub-side delay** in job routing after repo transfer (can take 10-30 minutes)

## Verification Steps

### 1. Check Repository Actions Settings

Go to: https://github.com/Beehive-Advisors/opentranscribe/settings/actions

**Check:**
- "Allow all actions and reusable workflows" is selected
- "Workflow permissions" → "Read and write permissions" is selected
- "Allow GitHub Actions to create and approve pull requests" is checked

### 2. Verify GitHub App Installation

Go to: https://github.com/organizations/Beehive-Advisors/settings/installations

**Check:**
- Find "actions-runner-controller-your-org"
- Click "Configure"
- Verify "Repository access" shows "All repositories" OR includes `opentranscribe`
- If "Only select repositories", click "Select repositories" and ensure `opentranscribe` is checked

### 3. Check Runner Visibility in GitHub

Go to: https://github.com/organizations/Beehive-Advisors/settings/actions/runners

**Check:**
- Runner `arc-runner-set-sc22p-24cpr` should be visible
- Status should be "Online" or "Idle"
- Labels should show: `self-hosted`, `arc-runner-set`

### 4. Force Runner Re-registration

If runner is not visible in GitHub UI:

```bash
# Delete runner pod to force re-registration
kubectl delete pod -n actions-runner-system arc-runner-set-sc22p-24cpr

# Wait for new pod
kubectl get pods -n actions-runner-system -w

# Check new runner logs
kubectl logs -n actions-runner-system -l runner-deployment-name=arc-runner-set -f
```

## Most Likely Issue

**GitHub Actions is disabled for the repository** after transfer. This is the most common cause.

**Fix:**
1. Go to repo Settings → Actions
2. Enable Actions
3. Set workflow permissions
4. Re-run workflow

## Alternative: Check GitHub Status

Sometimes GitHub has delays:
- Check: https://www.githubstatus.com/
- Look for "Actions" service status

## Next Steps

1. **Immediate**: Check Actions settings in repo (most likely fix)
2. **If still not working**: Check GitHub App installation
3. **If still not working**: Wait 10-30 minutes for GitHub sync
4. **Last resort**: Contact GitHub support or check ARC GitHub issues

