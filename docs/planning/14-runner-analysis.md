# Runner Analysis: Repo-Specific vs Org-Level

## Key Finding

**Repo-specific runner WORKED** - workflow #2 started building but was canceled during Docker layer download.

**Org-level runner NOT WORKING** - workflows stuck in "Queued" state.

## Why Repo-Specific Worked

Repo-specific runners (`repository: Beehive-Advisors/opentranscribe`) are explicitly scoped to the repository, so GitHub routes jobs immediately.

## Why Org-Level Isn't Working

Org-level runners (`organization: Beehive-Advisors`) may have a delay or caching issue after repo transfer. GitHub may need time to:
- Update internal routing tables for org-level runners
- Sync runner visibility to newly transferred repos
- Refresh job routing cache

## Options

### Option 1: Wait for Org-Level to Sync (Recommended)
- Keep using `arc-runner-set` (org-level)
- Wait 30-60 minutes for GitHub to sync
- This is the preferred long-term solution

### Option 2: Temporary Repo-Specific Runner
- Create repo-specific runner as temporary workaround
- Use until org-level syncs
- Then delete repo-specific and use org-level

### Option 3: Investigate GitHub API
- Check if there's a way to force GitHub to recognize org-level runner for new repo
- May require GitHub support or API call

## Current Status

- ✅ Repo-specific runner: Works immediately
- ⏳ Org-level runner: Waiting for GitHub sync
- ✅ Infrastructure: All correct

## Recommendation

Since repo-specific worked, the infrastructure is fine. The org-level runner will likely work once GitHub finishes syncing (30-60 min). For now, you could:

1. **Wait** for org-level to sync (preferred)
2. **Use repo-specific temporarily** if you need builds now
3. **Both** - keep repo-specific until org-level works, then switch

The failed build was just a cancellation during Docker pull - not a runner issue.

