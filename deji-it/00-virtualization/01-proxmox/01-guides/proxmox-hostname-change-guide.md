# How to Properly Change a Proxmox VE Hostname

Changing a Proxmox hostname isn't just an `/etc/hosts` edit. Proxmox ties the hostname to its cluster filesystem (`pmxcfs`), and — if corosync was ever configured, even briefly — to a cluster config that hardcodes the old name. Get it wrong and you can end up with a split node directory under `/etc/pve/nodes/`, or a "cluster not ready — no quorum" error blocking every VM from starting, even on a single standalone machine.

This guide is the safe, correct procedure, plus recovery steps if you're already in a bad state.

---

## Before you start

**Is this node part of a cluster (multiple Proxmox hosts joined together)?**

- **Standalone node** → follow this guide as-is.
- **Part of a multi-node cluster** → renaming is officially unsupported in place. The other nodes still know this host by its old name. The safe path is: remove the node from the cluster, rename it while standalone, then rejoin under the new name.

**Did you ever run `pvecm create` on this node, even as a test, even if you never actually joined another host to it?**

This matters more than it sounds like it should. If you did, this node has a `corosync.conf` sitting around with the old hostname baked into its nodelist — a leftover "cluster of one." That file will silently keep trying to start corosync on every boot, fail to parse it once the hostname changes, and pmxcfs will then refuse to consider itself "quorate" — which blocks VM starts even though nothing about your VMs is actually broken. Check with:
```bash
cat /etc/corosync/corosync.conf 2>/dev/null
```
If this file exists and you never actually intended to cluster, plan to remove it entirely (covered in the recovery section below) as part of your hostname change.

---

## Step-by-step procedure (standalone node, never clustered)

### 1. Back up first
```bash
cp -r /etc/pve/nodes/$(hostname)/qemu-server /root/qemu-server-backup
cp -r /etc/pve/nodes/$(hostname)/lxc /root/lxc-backup
```

### 2. Shut down (or note) running VMs/CTs
Not strictly required, but safer.

### 3. Set the new hostname using `hostnamectl`
```bash
hostnamectl set-hostname new-hostname
```
Don't just hand-edit `/etc/hostname` — `hostnamectl` makes sure everything that reads hostname state updates consistently.

### 4. Update `/etc/hosts`
Point the new hostname at the node's **real IP address**, not `127.0.1.1`:
```
192.168.1.50   new-hostname.yourdomain.com   new-hostname
```
Remove or update any old line pointing the old hostname at that same IP.

### 5. Restart the Proxmox stack (don't just edit and hope)
```bash
systemctl restart pve-cluster
systemctl restart pvestatd
systemctl restart pvedaemon
systemctl restart pveproxy
```
Or simplest and safest — just reboot:
```bash
reboot
```

### 6. Verify pmxcfs picked up the new identity
```bash
hostname
readlink -f /etc/pve/local
ls /etc/pve/nodes/
```
- `hostname` shows the new name.
- `/etc/pve/local` is a symlink to `/etc/pve/nodes/new-hostname`.
- `/etc/pve/nodes/` shows **only one** directory, with `qemu-server/`/`lxc/` and your configs already inside.

If you see two node directories, stop here and fix that before doing anything else — don't create new VMs on top of a half-migrated state.

### 7. Check corosync didn't wake up unhappy
```bash
systemctl status corosync --no-pager
pvecm status
```
If you never intended to cluster this node and corosync is `failed` with a parse error, or `pvecm status` complains about quorum, go to the recovery section below and remove the leftover cluster config.

### 8. Confirm in the web UI
- Only one node listed
- All VMs/CTs appear under it
- A VM actually boots successfully — don't consider this done until you've tested a real boot

---

## Recovery: split node directories (old + new both exist)

1. Stop the cluster service and remount pmxcfs locally to bypass its internal write restrictions:
   ```bash
   systemctl stop pve-cluster
   pmxcfs -l
   ```
2. Copy configs across using `cat` redirection rather than `cp` (more reliable on pmxcfs, and avoids weird "File exists" errors on stale internal entries):
   ```bash
   for f in /etc/pve/nodes/OLD-NAME/qemu-server/*.conf; do
     cat "$f" > /etc/pve/nodes/NEW-NAME/qemu-server/$(basename "$f")
   done
   ```
   (repeat for `/lxc/` if you have containers)
3. Verify each file copied correctly with `diff`.
4. Unmount local mode and restart normally:
   ```bash
   umount /etc/pve
   systemctl start pve-cluster
   ```
5. Confirm with `qm list` and the web UI before deleting the old node directory.
6. Only once every VM/CT is confirmed working:
   ```bash
   rm -rf /etc/pve/nodes/OLD-NAME
   ```

**Filename gotcha:** files under `qemu-server/`/`lxc/` must be named exactly `<VMID>.conf` — Proxmox won't recognize `100-backup.conf` or similar. Always finish with the exact `<VMID>.conf` name, or `qm list` and the web UI will show nothing even though the data is right there on disk.

---

## Recovery: "cluster not ready — no quorum" on a node that should be standalone

This happens when a leftover `corosync.conf` (from a past `pvecm create` you never finished) still references the old hostname. Corosync fails to parse/start, and pmxcfs then waits forever for quorum that will never come — blocking VM starts.

```bash
# 1. Stop everything
systemctl stop pve-cluster corosync

# 2. Remount pmxcfs locally so you can edit /etc/pve without quorum
pmxcfs -l

# 3. Remove the corosync config pmxcfs itself tracks
rm /etc/pve/corosync.conf

# 4. Unmount local mode
umount /etc/pve

# 5. Remove the on-disk corosync config and state
rm -f /etc/corosync/corosync.conf
rm -rf /etc/corosync/files
rm -rf /var/lib/corosync/*

# 6. Disable corosync entirely — a real standalone node doesn't need it
systemctl disable --now corosync

# 7. Restart pve-cluster; with no corosync.conf present it starts in standalone mode
systemctl restart pve-cluster

# 8. Verify
pvecm status
qm start <vmid>
```

---

## Quick checklist for next time

- [ ] Confirm standalone vs. clustered before doing anything
- [ ] Check for a leftover `/etc/corosync/corosync.conf` from any past `pvecm create`
- [ ] Back up `/etc/pve/nodes/$(hostname)/{qemu-server,lxc}` first
- [ ] Use `hostnamectl set-hostname` — don't hand-edit only
- [ ] Update `/etc/hosts` to point the new hostname at the real IP
- [ ] Restart `pve-cluster`, `pvestatd`, `pvedaemon`, `pveproxy` — or just reboot
- [ ] Verify `/etc/pve/nodes/` shows exactly one directory
- [ ] Check `pvecm status` / `corosync` isn't failing on a stale nodelist
- [ ] Confirm the web UI shows all VMs/CTs and a VM actually boots before calling it done
