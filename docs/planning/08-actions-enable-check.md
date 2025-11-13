# Actions May Be Disabled After Transfer

## Issue
Workflow stuck waiting for runner even though everything is configured correctly.

## Possible Cause
After transferring a repository, GitHub Actions may be disabled or need to be re-enabled.

## Fix

### Step 1: Enable Actions for Repository

1. Go to: https://github.com/Beehive-Advisors/opentranscribe/settings/actions
2. Under "Actions permissions":
   - Select **"Allow all actions and reusable workflows"** OR
   - Select **"Allow local actions and reusable workflows"** (if you want to restrict)
3. Under "Workflow permissions":
   - Select **"Read and write permissions"** (needed for updating manifests)
4. Click **Save**

### Step 2: Verify GitHub App Installation

1. Go to: https://github.com/organizations/Beehive-Advisors/settings/installations
2. Find the "actions-runner-controller-your-org" app
3. Click "Configure"
4. Scroll to "Repository access"
5. Ensure it shows "All repositories" OR includes `opentranscribe`
6. If it shows "Only select repositories", click "Select repositories" and add `opentranscribe`

### Step 3: Re-run Workflow

After enabling Actions:
1. Go to: https://github.com/Beehive-Advisors/opentranscribe/actions
2. Click on the waiting workflow
3. Click "Re-run all jobs"

Or push a new commit:
```bash
git commit --allow-empty -m "Re-trigger after enabling Actions"
git push origin main
```

## Why This Happens

When a repo is transferred:
- Actions may be disabled by default
- GitHub App installation may need to refresh
- Workflow permissions may reset

This is a common issue after transfers.

