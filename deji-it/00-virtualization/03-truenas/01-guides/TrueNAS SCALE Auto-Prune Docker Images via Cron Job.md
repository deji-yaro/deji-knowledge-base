## Step 1: Access Cron Jobs
1. Log into TrueNAS web UI
2. Navigate to **Tasks → Cron Jobs**
3. Click **Add**

## Step 2: Configure the Cron Job

| Field | Value |
|-------|-------|
| **Description** | `Docker Image Prune` |
| **Command** | `docker image prune -af --filter "until=168h"` |
| **Run As User** | `root` |
| **Schedule** | Custom: `0 3 * * 0` (Every Sunday at 3 AM) |
| **Enabled** | ✓ Checked |
| **Hide Standard Output** | ✓ Checked (optional, reduces log noise) |
| **Hide Standard Error** | ✓ Checked (optional) |

### Schedule Examples:
- **Weekly (Sunday 3 AM):** `0 3 * * 0`
- **Bi-weekly:** `0 3 * * 0` and set "Only Run Once" with custom interval
- **Monthly (1st @ 3 AM):** `0 3 1 * *`
- **Daily at 2 AM:** `0 2 * * *`

## Step 3: Save & Verify

1. Click **Submit**
2. Verify the job appears in the Cron Jobs list
3. Optional: Click the **play button** next to the job to test-run it immediately

## Step 4: Monitor Results

Check if it's working:

```bash
# View cron execution logs
grep "CRON" /var/log/cron.log

# Or check system logs
tail -f /var/log/messages | grep prune

# Manually verify image count before/after
docker images | wc -l
du -sh /var/lib/docker
```

## What This Does:
- `-a`: Remove all unused images, not just dangling ones
- `-f`: Force removal without confirmation prompt
- `--filter "until=168h"`: Only remove images not used in the last 7 days (168 hours)

This prevents breaking apps that might need recently-pulled images while cleaning up old accumulated layers from app updates.

## Adjust Filter If Needed:
- More aggressive (3 days): `--filter "until=72h"`
- More conservative (14 days): `--filter "until=336h"`