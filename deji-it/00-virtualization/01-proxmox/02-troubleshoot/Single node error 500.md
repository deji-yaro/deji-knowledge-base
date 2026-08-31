This is a common Proxmox issue when you have a cluster configured but not all nodes are online. The problem is **quorum**.

---

## Why This Happens

Proxmox uses **Corosync** for cluster communication and requires **quorum** (majority of nodes online) before it allows VM operations. With a multi-node cluster and only 1 node online, quorum is lost by default.

---

## Fix: Force Quorum on the Single Online Node

SSH into your online node and run:

```bash
pvecm expected 1
```

This tells Corosync to expect only 1 node, restoring quorum temporarily so you can manage VMs.

---

## Verify It Worked

```bash
pvecm status
```

Look for:

```
Quorate: Yes
```

You should now be able to launch VMs from the web interface.

---

## If That's Not Enough — Check Corosync Service

```bash
systemctl status corosync
systemctl status pve-cluster
```

If either is failed, restart them:

```bash
systemctl restart corosync
systemctl restart pve-cluster
```

---

## Permanent Fix Options

If you regularly run with just 1 node, consider:

|Option|Description|
|---|---|
|**Remove other nodes** from cluster|Clean single-node setup, no quorum issues|
|**Add a QDevice**|Lightweight quorum device (Raspberry Pi, VM) acts as a tiebreaker|
|**Set expected votes to 1 permanently**|Edit `/etc/corosync/corosync.conf` → set `expected_votes: 1`|

---

## ⚠️ Warning

`pvecm expected 1` is a **temporary override** — it resets on Corosync restart. It's fine for maintenance but don't rely on it long term in production.