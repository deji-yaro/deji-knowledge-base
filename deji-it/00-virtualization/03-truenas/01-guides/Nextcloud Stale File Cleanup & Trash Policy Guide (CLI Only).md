## Part 1: Identify Stale Files via CLI (Inside Container)

Run these commands inside the Nextcloud container to audit space consumers before touching anything.

### Audit Trashbin Size Per User
```bash
# List trashbin usage for ALL users, sorted largest first
du -sh /var/www/html/data/*/files_trashbin | sort -rh

# Check age of oldest trash files (confirm they're truly stale)
find /var/www/html/data/*/files_trashbin -type f -mtime +30 | wc -l
```

### Audit Orphaned Uploads
```bash
# Show upload dir size per user
du -sh /var/www/html/data/*/uploads | sort -rh

# Count files older than 24 hours (safe to delete)
find /var/www/html/data/*/uploads -type f -mtime +1 | wc -l

# Preview top 20 largest orphaned uploads
find /var/www/html/data/*/uploads -type f -mtime +1 -exec ls -lh {} \; | sort -k5 -rh | head -20
```

### Audit Appdata Cache Bloat
```bash
# Check preview/cache size per user
du -sh /var/www/html/data/appdata_*/preview | sort -rh

# Count total preview files
find /var/www/html/data/appdata_*/preview -type f | wc -l
```

> **Safety Rule:** Never delete files modified within the last 24 hours from `uploads/`. Those may be active transfers. Trashbin and appdata previews are always safe to clean via OCC.

---

## Part 2: Clean Up Stale Files

### Empty Trashbin (All Users or Specific)
```bash
# All users at once
su -s /bin/bash www-data -c "php occ trashbin:cleanup --all-users"

# Single user only
su -s /bin/bash www-data -c "php occ trashbin:cleanup <username>"
```

### Clear Stale Previews
```bash
su -s /bin/bash www-data -c "php occ preview:cleanup"
```

### Remove Orphaned Uploads Older Than 24 Hours
```bash
find /var/www/html/data/*/uploads -type f -mtime +1 -delete
```

### Verify Space Freed (On TrueNAS Host Shell)
```bash
zfs list -o used,referenced deji-apps/ix-apps/app_mounts/nextcloud/data
```

Compare `used` before and after. ZFS reclaims space immediately on deletion (no snapshot holding it back).

---

## Part 3: Set Trashbin Retention Policy via `config.php`

Since the Web GUI is unavailable, configure retention directly in `/var/www/html/config/config.php`.

### Steps
1.  Edit `config.php` inside the container (or via host path `/mnt/.ix-apps/app_mounts/nextcloud/html/config/config.php`).
2.  Add this line to the `$CONFIG` array (before the closing `);`):
    ```php
    'trashbin_retention_obligation' => 'auto, 7',
    ```
3.  Save the file.
4.  Fix ownership:
    ```bash
    chown www-data:www-data /var/www/html/config/config.php
    ```
5.  Verify the setting is loaded:
    ```bash
    su -s /bin/bash www-data -c "php occ config:app:get files_trashbin retention_obligation"
    ```
    Expected output: `auto, 7`

### What This Does
-   Files deleted less than ~3 days ago are **never** removed automatically.
-   Files deleted more than 7 days ago are **always** removed on next background job run.
-   Files between 3–7 days are removed only if storage quota pressure exists.

> **Note:** This setting controls *automatic* cleanup. It does not retroactively delete existing trash. Run `occ trashbin:cleanup --all-users` once manually after changing this policy to clear legacy accumulated trash.

### ⚠️ Persistence Warning
TrueNAS SCALE regenerates `config.php` during **Nextcloud app updates** (not reboots). Your edit will survive restarts but will be lost when you update the Nextcloud app via the TrueNAS UI. Before updating the app, either back up your custom lines or migrate them to a `custom.config.php` fragment file.

---

## Part 4: Make Cleanup Persistent (TrueNAS Cron Jobs)

Container-level cron is unreliable in TrueNAS SCALE. Enforce cleanup from the host.

### Cron Job 1: Daily Trash Cleanup
| Field | Value |
| :--- | :--- |
| Description | `Nextcloud Trash Cleanup` |
| Command | `docker exec <container-name> su -s /bin/bash www-data -c "php occ trashbin:cleanup --all-users"` |
| Schedule | `0 4 * * *` |
| Run As | `root` |

### Cron Job 2: Daily Upload Orphan Removal
| Field | Value |
| :--- | :--- |
| Description | `Nextcloud Stale Upload Cleanup` |
| Command | `docker exec <container-name> find /var/www/html/data/*/uploads -type f -mtime +1 -delete` |
| Schedule | `30 3 * * *` |
| Run As | `root` |

Replace `<container-name>` with your actual Nextcloud container name (`docker ps` to find it).

---

## Quick Reference: Safe vs Unsafe Operations

| Action | Safe? | Notes |
| :--- | :--- | :--- |
| `occ trashbin:cleanup` | ✅ Always | Designed for this purpose |
| `occ preview:cleanup` | ✅ Always | Regenerates on next access |
| Delete `uploads/*` >24h old | ✅ Safe | Active uploads are <24h old |
| Delete `uploads/*` <24h old | ❌ Risky | May interrupt live transfers |
| Delete `files/` directly | ❌ NEVER | Corrupts Nextcloud database references |
| Delete `appdata_*/` directly | ❌ NEVER | Breaks app functionality |