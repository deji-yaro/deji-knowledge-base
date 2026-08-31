# Technitium DNS Server — Update Guide
**System:** Debian (amd64) · Proxmox LXC Container

---

## Overview

Technitium DNS is **not** managed by `apt`, so `apt upgrade` will not update it.
It has its own installer script that handles both fresh installs and in-place upgrades.

---

## Pre-Update: Snapshot Your LXC (Recommended)

Before updating, take a snapshot from the Proxmox web UI as a safety net:

> **Proxmox UI → Your LXC Container → Snapshots → Take Snapshot**

---

## Step 1 — Update OS Packages

SSH into your LXC container or open the Proxmox console, then:

```bash
apt update && apt upgrade -y
```

---

## Step 2 — Ensure dotnet is Globally Accessible

Technitium requires the ASP.NET Core Runtime at `/usr/bin/dotnet`.
Check if the symlink exists:

```bash
ls -la /usr/bin/dotnet
```

If it is missing or broken, recreate it:

```bash
rm -f /usr/bin/dotnet
ln -s /opt/dotnet/dotnet /usr/bin/dotnet
```

---

## Step 3 — Kill Any Stale Technitium Process

A leftover process on port 5380 will block the update. Clear it first:

```bash
kill -9 $(ss -tlnp sport = :5380 | awk 'NR>1 {print $6}' | grep -oP 'pid=\K[0-9]+')
```

> It's safe to run even if nothing is on that port — it will just do nothing.

---

## Step 4 — Run the Technitium Installer

Run the official installer script as root (drop `sudo` since you are already root):

```bash
curl -sSL https://download.technitium.com/dns/install.sh | bash
```

You should see:

```
===============================
Technitium DNS Server Installer
===============================
Updating ASP.NET Core Runtime...
ASP.NET Core Runtime was updated successfully!
Downloading Technitium DNS Server...
Updating Technitium DNS Server...
Technitium DNS Server was installed successfully!
```

---

## Step 5 — Restart and Verify the Service

```bash
systemctl restart dns.service && sleep 5 && systemctl status dns.service
```

Expected output includes:

```
Active: active (running)
Technitium DNS Server was started successfully.
```

---

## Step 6 — Confirm in the Web UI

Open your browser and navigate to:

```
http://<your-technitium-hostname>:5380/
```

The login page should load. After signing in, confirm the new version number at the top of the dashboard.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `Failed to install ASP.NET Core Runtime` | The runtime actually installed fine. Check symlink in Step 2 and retry. |
| `address already in use` on port 5380 | Run the kill command in Step 3, then restart the service. |
| Web UI shows `Parameter 'token' missing` | Service is not running properly — check `systemctl status dns.service` and `journalctl -u dns.service -n 50 --no-pager`. |
| `dotnet: command not found` | Recreate the symlink as shown in Step 2. |

---

## Useful Commands

```bash
# Check service status
systemctl status dns.service

# View recent logs
journalctl -u dns.service -n 50 --no-pager

# Check what is using port 5380
ss -tlnp sport = :5380

# Check installed dotnet runtime
ls /opt/dotnet/shared/Microsoft.AspNetCore.App/
```

---

*Last updated: April 2026 · Technitium DNS Server v15.0.1*
