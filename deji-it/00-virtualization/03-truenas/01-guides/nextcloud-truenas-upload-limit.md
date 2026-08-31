# Nextcloud Upload Limit Fix — TrueNAS SCALE (Community Edition)

## Environment

- **TrueNAS Edition:** SCALE Community 25.04
- **Nextcloud deployment:** TrueNAS Apps (Docker/Kubernetes via Helm)
- **Access method:** Cloudflare Tunnel → domain → Nextcloud on port 9000

---

## Problem

Large file uploads (e.g. 50 GB graphic files) were failing with an error in the Nextcloud web interface. Uploads via SMB/NFS to the same pool worked without issue, pointing to a Nextcloud/PHP-level restriction rather than a storage or network problem.

---

## Root Cause

PHP settings inside the Nextcloud container were too conservative for large uploads:

| Setting | Old Value | Issue |
|---|---|---|
| PHP Upload Limit | 10 GB | Below the required file size |
| Max Execution Time | 500 seconds | Too short for large uploads over slow connections |
| PHP Memory Limit | 512 MB | Can cause silent failures on very large files |

---

## Fix

Navigate to: **TrueNAS UI → Apps → Nextcloud → Edit**

Change the following values and save (the app will redeploy automatically):

| Field | Recommended Value |
|---|---|
| PHP Upload Limit (GB) | `100` |
| Max Execution Time (seconds) | `7200` |
| PHP Memory Limit (MB) | `1024` |

---

## Notes

- SMB/NFS uploads bypass PHP entirely, which is why they were unaffected.
- Cloudflare Tunnel (free plan) has a 100 MB per-request cap for browser uploads — for very large files via browser, the **Nextcloud desktop client** is recommended as it chunks uploads automatically.
- Dataset quotas on the TrueNAS pool can also cap storage — check under **Storage → your dataset → Edit** if issues persist after the PHP fix.

---

## Result

After applying the PHP changes, large file uploads (50 GB+) completed successfully through the Nextcloud web interface.
