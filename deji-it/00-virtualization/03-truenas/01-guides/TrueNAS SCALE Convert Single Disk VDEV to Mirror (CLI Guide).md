## Critical Warning
This guide uses `zpool attach`, which **preserves all data on the existing disk**. However, if you use the wrong command (`zpool replace` or `zpool add`), you will either fail to create a mirror or risk data loss. **Follow these steps exactly.**

---

## Prerequisites

-   New disk must be **equal to or larger** than the existing disk.
-   New disk should be **wiped** before attaching (TrueNAS may refuse dirty disks).
-   Pool must be **ONLINE and healthy** — no degraded state or errors.
-   Have a **recent backup** as a safety net.

---

## Step 1: Identify Existing Disk Identifier

```bash
sudo zpool status <pool-name>
```

Look at the `NAME` column under your pool. Copy the **exact string** for the single disk in the VDEV. It will be either:
-   A `/dev/disk/by-id/...` path, **or**
-   A GUID like `e9851ceb-2532-4e6f-943c-d3bedae28410`

You must use this verbatim in Step 3.

---

## Step 2: Wipe the New Disk

```bash
# Find the new disk's by-id path
ls -la /dev/disk/by-id/ | grep <new-disk-model-or-serial>

# Wipe filesystem signatures
sudo wipefs -a /dev/disk/by-id/<new-disk-id>

# Clear any old ZFS labels
sudo zpool labelclear -f /dev/disk/by-id/<new-disk-id>
```

> **DO NOT wipe the existing disk.** Only the new disk gets wiped.

---

## Step 3: Attach New Disk to Create Mirror

```bash
sudo zpool attach <pool-name> \
  <existing-disk-identifier-from-step-1> \
  /dev/disk/by-id/<new-disk-id>
```

**Example:**
```bash
sudo zpool attach deji-bck \
  e9851ceb-2532-4e6f-943c-d3bedae28410 \
  /dev/disk/by-id/ata-ST8000VX004-2M1101_WKD155PW
```

If successful, the command returns silently with no error. TrueNAS UI may pop up a "Resilvering Status" dialog automatically.

---

## Step 4: Monitor Resilver Progress

```bash
# Live watch (updates every 2 seconds)
watch -n 2 sudo zpool status <pool-name>
```

You should see:
```
mirror-0    ONLINE       0     0     0
  e9851ceb...              ONLINE       0     0     0
  ata-ST8000VX004-...      ONLINE       0     0     0  (resilvering)
```

The `(resilvering)` tag and percentage indicate active copying. For an 8 TB drive, expect **12–24 hours**.

> ️ **Do NOT proceed to Step 5 until resilver reaches 100% and the `(resilvering)` tag disappears.**

---

## Step 5: Enforce Consistent Device Naming

After resilver completes, your `zpool status` may show mixed identifiers (GUID + by-id path). To fix this:

```bash
# Export the pool (goes offline briefly)
sudo zpool export <pool-name>

# Re-import using explicit device directory
# Use 'by-id' for consistent symlink-based naming:
sudo zpool import -d /dev/disk/by-id <pool-name>

# OR use 'by-uuid' if you prefer GUIDs everywhere:
# sudo zpool import -d /dev/disk/by-uuid <pool-name>
```

Verify consistency:
```bash
sudo zpool status <pool-name>
```

Both disks should now display with the same identifier format.

---

## Step 6: Final Verification

Confirm the mirror is complete and healthy:
-   Both disks listed under `mirror-0`
-   **No** `(resilvering)` tag
-   State: `ONLINE` for both disks
-   No errors in READ/WRITE/CKSUM columns
-   Consistent naming across both devices

Your single-disk VDEV is now a true RAID1/mirror with uniform device references.

---

## Troubleshooting

| Problem | Cause | Fix |
| :--- | :--- | :--- |
| `no such device in pool` | Used wrong identifier format | Use the **exact string** from `zpool status` |
| `device is busy` | Disk has active partitions/ZFS labels | Run `wipefs -a` and `zpool labelclear -f` on new disk |
| Resilver stalls at 0% | Disk error or I/O contention | Check `dmesg \| tail -50`; reduce pool I/O load |
| `invalid vdev specification` | New disk smaller than existing | Replace with equal/larger disk |
| Mixed naming after attach | Expected behavior; cosmetic only | Complete Step 5 after resilver finishes |

### Abort Mid-Resilver (Emergency Only)
```bash
sudo zpool detach <pool-name> /dev/disk/by-id/<new-disk-id>
```
This removes the new disk and reverts to single-disk. Original data is untouched.