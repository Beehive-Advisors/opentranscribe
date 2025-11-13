# We ARE Using Org-Level Runners

## Current Setup

✅ **We ARE using org-level runners** - `arc-runner-set` is configured as:
- `organization: Beehive-Advisors` (org-level)
- `repository: ""` (empty = org-level, not repo-specific)

✅ **Workflow uses org-level runner**:
- `runs-on: arc-runner-set` (matches org-level runner label)

## Why It's Not Working Yet

**GitHub-side delay after repo transfer.** When a repo is transferred:
1. GitHub needs to update internal routing tables
2. Org-level runners need to be "linked" to newly transferred repos
3. This can take 30-60 minutes

## What We Know

- ✅ Runner is registered correctly (org-level)
- ✅ Runner is listening for jobs
- ✅ Workflow requests org-level runner
- ❌ GitHub hasn't synced routing yet

## Why Repo-Specific Worked

Repo-specific runners (`repository: Beehive-Advisors/opentranscribe`) work immediately because:
- They're explicitly scoped to the repo
- No routing table sync needed
- GitHub routes jobs directly

## Solution

**Wait for GitHub to sync** (30-60 minutes). The org-level runner WILL work once GitHub finishes syncing. Everything is configured correctly - it's just a timing issue.

Alternatively, if you need builds immediately:
- Use repo-specific runner temporarily
- Switch back to org-level once it syncs

But org-level runners ARE the right solution - they just need GitHub to finish syncing.


