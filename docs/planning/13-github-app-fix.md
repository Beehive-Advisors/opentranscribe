# GitHub App Permission Issue

## Problem
Runner is listening but not picking up jobs from the newly transferred repository.

## Root Cause
The GitHub App that authenticates the ARC runner needs to be granted access to the `opentranscribe` repository.

## Solution

### Step 1: Grant GitHub App Access to Repository

1. Go to GitHub organization settings: https://github.com/organizations/Beehive-Advisors/settings/apps
2. Find the GitHub App used by ARC (usually named something like "actions-runner-controller" or similar)
3. Click on the app
4. Go to "Repository access" section
5. Either:
   - Select "All repositories" (if you want it to access all org repos)
   - OR select "Only select repositories" and add `opentranscribe`

### Step 2: Verify Repository Actions Settings

1. Go to: https://github.com/Beehive-Advisors/opentranscribe/settings/actions
2. Under "Workflow permissions", ensure:
   - "Read and write permissions" is selected (or "Read repository contents and packages permissions")
   - "Allow GitHub Actions to create and approve pull requests" is checked (if needed)

### Step 3: Restart Runner (After App Access Granted)

```bash
kubectl delete pod -n actions-runner-system -l runner-deployment-name=arc-runner-set
```

The runner will automatically restart and should now pick up jobs.

## Alternative: Check GitHub App Installation

If you can't find the app in org settings, check:

1. Go to: https://github.com/organizations/Beehive-Advisors/settings/installations
2. Find the ARC GitHub App installation
3. Click "Configure"
4. Under "Repository access", add `opentranscribe` if it's not already included

## Verification

After granting access:
1. Wait ~30 seconds for runner to reconnect
2. Check GitHub Actions - workflow should start running
3. Monitor runner logs: `kubectl logs -n actions-runner-system -l runner-deployment-name=arc-runner-set -f`

