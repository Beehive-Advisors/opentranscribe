# Workflow Debugging - Still Waiting for Runner

## What We've Verified
- ✅ Runner is registered and listening
- ✅ Runner labels match: `arc-runner-set`
- ✅ GitHub App installed with "All repositories" access
- ✅ Actions enabled for repo
- ✅ Workflow file matches working ARC setup (comment removed)
- ✅ Workflow file is committed and pushed

## Still Not Working - Check These

### 1. Workflow Approval Requirements
**Check Org Settings:**
- Go to: https://github.com/organizations/Beehive-Advisors/settings/actions
- Under "Workflow permissions":
  - Check if "Require approval for all outside collaborators" is enabled
  - Check if "Require approval for first-time contributors" is enabled

**Check Repo Settings:**
- Go to: https://github.com/Beehive-Advisors/opentranscribe/settings/actions
- Under "Workflow permissions":
  - Check if workflow approval is required

### 2. Branch Protection Rules
- Go to: https://github.com/Beehive-Advisors/opentranscribe/settings/branches
- Check if `main` branch has protection rules
- Look for "Require status checks to pass before merging"
- Check if workflows need approval

### 3. GitHub API Rate Limiting
GitHub may be rate-limiting job routing. Check:
- https://www.githubstatus.com/
- Wait 10-15 minutes and try again

### 4. Runner Visibility in Repo
**Check if runner is visible at repo level:**
- Go to: https://github.com/Beehive-Advisors/opentranscribe/settings/actions/runners
- See if `arc-runner-set-sc22p-*` appears in the list
- If not, GitHub may not be routing jobs to org-level runners for this repo

### 5. Workflow File Validation
**Check workflow syntax in GitHub:**
- Go to: https://github.com/Beehive-Advisors/opentranscribe/actions
- Click on the workflow run
- Check if there are any validation errors
- Look for yellow warning icons

### 6. Manual Workflow Trigger
Try triggering workflow manually:
- Go to: https://github.com/Beehive-Advisors/opentranscribe/actions/workflows/backend-build.yml
- Click "Run workflow" dropdown
- Select branch: `main`
- Click "Run workflow"

### 7. Check GitHub Actions Logs
In the workflow run page, check:
- Are there any error messages?
- Does it show "Waiting for runner" or something else?
- Check the "Jobs" tab for details

## Nuclear Option: Create Repository-Scoped Runner

If org-level runner still doesn't work, we could create a repo-specific runner:

```yaml
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: opentranscribe-runner
  namespace: actions-runner-system
spec:
  replicas: 1
  template:
    spec:
      repository: Beehive-Advisors/opentranscribe
      labels:
      - self-hosted
      - opentranscribe-runner
      dockerEnabled: true
      dockerdWithinRunnerContainer: true
```

Then update workflow: `runs-on: opentranscribe-runner`

But this should NOT be necessary - org-level runners should work.

## Most Likely Issue

Given everything is configured correctly, this is likely:
1. **GitHub-side delay** after repo transfer (can take 30+ minutes)
2. **Workflow approval requirement** that needs to be satisfied
3. **GitHub API caching** that needs to refresh

Try waiting 15-30 minutes, then manually trigger the workflow.

