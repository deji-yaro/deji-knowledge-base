## The Command

Run this **from the Proxmox host shell** (not inside the LXC):

```bash
var_cpu="1" var_ram="512" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/nginxproxymanager.sh)"
```

When prompted, select **Update**.

---

## Why the `var_cpu` / `var_ram` Prefix?

The community script defaults to **2 vCPU / 2048 MB RAM** for new installs [[source]]. When you run it against an existing container in update mode, it can attempt to resize resources to those defaults — bloating a lightweight container.

Prefixing the command overrides those variables for that single execution:

| Variable | Default | Your Value | Purpose |
|----------|---------|------------|---------|
| `var_cpu` | 2 | 1 | vCPU cores |
| `var_ram` | 2048 | 512 | RAM in MB |

This keeps your LXC at its intended footprint during the update.

---

## What the Script Actually Does

1. Detects the existing NPM installation in the selected LXC
2. Checks GitHub for the latest `NginxProxyManager/nginx-proxy-manager` release
3. Stops `openresty` and `npm` systemd services
4. Downloads and extracts the new tarball into `/opt/nginxproxymanager`
5. Cleans stale files (`/app`, `/var/www/html`, old nginx dirs)
6. Reinstalls Node dependencies and rebuilds the frontend
7. Restarts services

It updates **both** the NPM app and handles the OpenResty side — which is why `apt upgrade` alone never bumped your version.

---

## Quick Reference Card

```bash
# Standard update (keeps 1 CPU / 512 MB)
var_cpu="1" var_ram="512" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/nginxproxymanager.sh)"

# Verify after update (inside the LXC)
nginx -v                              # OpenResty version
systemctl status npm openresty        # Both should be active
curl -s http://localhost:81           # Web UI responds
```

Check the bottom-left of the NPM web UI — the "Update Available" banner should be gone.

---

## Automating It (Optional)

The script is interactive, so full automation requires piping input. From the **Proxmox host**:

```bash
# crontab -e on the Proxmox host
# Weekly Sunday 3am, auto-selects UPDATE option
0 3 * * 0 echo "UPDATE" | var_cpu="1" var_ram="512" bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/nginxproxymanager.sh)" >> /var/log/npm-update.log 2>&1
```

⚠️ Test manually with logging first. If upstream changes the prompt flow, this breaks silently. For production, prefer a custom non-interactive updater script instead.

---

## Gotchas

- **Run from Proxmox host**, not inside the LXC — the script uses `pct` commands to reach into the container
- **Always snapshot first** if you care about rollback: `pct snapshot <CTID> pre-npm-update`
- **Don't omit the var overrides** unless you actually want 2 CPU / 2 GB RAM assigned
- The script source is public — worth a quick read before trusting it on production: [nginxproxymanager.sh](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/nginxproxymanager.sh)