## Service Won't Start / Connection Refused

### 1. Identify the correct service name
```bash
systemctl list-units | grep -i technitium
# Common names: technitium.service, technitium-dns.service, dns.service
```

### 2. Check service status and logs
```bash
systemctl status technitium.service
journalctl -u technitium.service --no-pager -n 100
```
> ⚠️ **Use the exact unit name from step 1.** Wrong name = "No entries" and wasted time.

### 3. Check if it's listening
```bash
ss -tlnp | grep -E '5380|53443|53'
```
- **Port present** → Service is running, issue is firewall/networking
- **Port absent** → Service crashed on startup, check logs

### 4. Test manual start for direct error output
```bash
/usr/bin/dotnet /opt/technitium/dns/DnsServerApp.dll /etc/dns
```
This prints exceptions to stdout — often faster than journalctl for crash loops.

---

## Common Failure Causes & Fixes

### Permission Denied on Logs/Config
**Symptom:** `System.UnauthorizedAccessException: Access to the path '/etc/dns/logs/...' is denied`

**Cause:** Update script or manual cleanup ran as root, breaking ownership for the `dns-server` service user.

**Fix:**
```bash
# Verify service user
grep -E '^User=|^Group=' /etc/systemd/system/technitium.service

# Fix ownership (replace dns-server with actual user from above)
chown -R dns-server:dns-server /etc/dns/
find /etc/dns/ -type d -exec chmod 750 {} \;
find /etc/dns/ -type f -exec chmod 640 {} \;

systemctl restart technitium.service
```

### .NET Runtime Mismatch
**Symptom:** Service exits immediately, logs mention framework version errors.

**Check:**
```bash
dotnet --info
cat /opt/technitium/dns/DnsServerApp.runtimeconfig.json
```
Compare installed runtime version against `targetFramework` in runtimeconfig.json.

**Fix:** Install matching .NET runtime or roll back Technitium version.

### Disk Full
**Symptom:** Service crash-loops, various IO errors, `df -h` shows >90%.

**Triage:**
```bash
du -xh --max-depth=1 / | sort -hr
du -xh --max-depth=2 /var | sort -hr
```

**Quick wins:**
```bash
journalctl --vacuum-size=30M
apt clean && apt autoremove -y
rm -rf /var/lib/apt/lists/*
```

**Long-term:** Resize rootfs from Proxmox host:
```bash
pct resize <VMID> rootfs 8G
# Filesystem auto-expands for LXC — no resize2fs needed
```

### Config Corruption After Update
**Symptom:** Service starts but behaves unexpectedly or won't bind.

**Check for backups:**
```bash
ls -la /etc/dns/*.bak /etc/dns/config-backup/ /var/backups/technitium* 2>/dev/null
```

**Restore:** Copy backup config over current, fix ownership, restart.

---

## Post-Update Verification Checklist

Run these after **every** update (official or community):

```bash
# 1. Service is running
systemctl is-active technitium.service

# 2. Web UI is listening
ss -tlnp | grep 5380

# 3. Log directory ownership is correct
ls -la /etc/dns/logs/
# Owner should match User= in systemd unit file

# 4. No permission errors in recent logs
journalctl -u technitium.service --since "5 min ago" | grep -i "denied\|exception\|error"

# 5. DNS resolution works
dig @127.0.0.1 example.com +short
```

---

## Key Paths Reference

| Path | Purpose |
|---|---|
| `/etc/dns/` | Config, zones, logs |
| `/etc/dns/logs/` | Application logs |
| `/opt/technitium/dns/` | Application binaries |
| `/etc/systemd/system/technitium.service` | Systemd unit file |
| `/var/log/technitium/` | Alternate log location (some installs) |

---

## Prevention Rules

1. **Never delete/modify files in `/etc/dns/` as root** without fixing ownership afterward
2. **Always verify service user** before chown/chmod operations
3. **Back up `/etc/dns/` before any update**: `tar czf /root/technitium-backup-$(date +%F).tar.gz /etc/dns/`
4. **Review community scripts before running** — check for proper user handling
5. **Set disk monitoring** at 80% threshold to avoid emergency cleanups