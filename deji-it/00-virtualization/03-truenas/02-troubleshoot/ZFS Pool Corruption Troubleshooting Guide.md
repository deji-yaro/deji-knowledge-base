## 1. Check Pool Status

```bash
# Basic pool health overview
zpool status <pool_name>

# Detailed view with error list
zpool status -v <pool_name>

# Real-time I/O stats (refreshes every 1 second, 5 iterations)
zpool iostat -v <pool_name> 1 5
```

### Reading `zpool status` Output

```
  pool: [POOL]
 state: ONLINE                          ← Pool state (ONLINE/DEGRADED/FAULTED)
status: One or more devices...          ← Warning message if issues exist
action: Restore the file...             ← Recommended action
  scan: scrub repaired 0B in 02:08:42   ← Last scrub results
        with 0 errors on Sun Jul 5...   ← Errors found during scrub

config:
        NAME                    STATE     READ WRITE CKSUM
        [POOL]             ONLINE       0     0     0    ← Pool-level counters
          mirror-0              ONLINE       0     0     0    ← Vdev type (mirror/stripe)
            sde                 ONLINE       0     0     0    ← Individual disk counters
            sdg                 ONLINE       0     0     0

errors: No known data errors    ← Clean state
errors: 140 data errors         ← Permanent corruption detected
```

**Key Fields:**
- **STATE**: `ONLINE` = healthy, `DEGRADED` = redundancy lost, `FAULTED` = pool unusable
- **READ/WRITE/CKSUM**: Non-zero values indicate hardware or data integrity issues
  - `READ`/`WRITE` = physical I/O errors (cable, controller, disk failure)
  - `CKSUM` = checksum mismatches (bit rot, RAM issues, silent corruption)
- **Vdev layout**:
  - `mirror-X` = redundant (can self-heal)
  - No prefix = stripe/RAID0 (no redundancy, cannot self-heal)

---

## 2. List Corrupted Files

```bash
# Show all files with permanent checksum errors
zpool status -v <pool_name> | grep -A 999 "errors:"

# Extract just file paths (exclude snapshot references)
zpool status -v <pool_name> | grep "^        /mnt/" | awk '{print $1}'

# Count corrupted files
zpool status -v <pool_name> | grep -c "^        /mnt/"
```

### Understanding Error Paths

```
[POOL]@auto-2026-07-20_00-00:/path/to/file.jpg
↑ Snapshot reference (historical, may be stale)

[POOL]/path/to/file.jpg
↑ Live filesystem path (current data)
```

**Note:** Snapshot entries (`@auto-...`) represent corruption captured at snapshot time. If live files read cleanly, the corruption may have been corrected by subsequent writes (COW behavior).

---

## 3. Manual Scrub Operations

```bash
# Start a full pool scrub
zpool scrub <pool_name>

# Monitor scrub progress
zpool status <pool_name>

# Cancel an ongoing scrub
zpool scrub -s <pool_name>

# Check scrub history
zpool history <pool_name>
```

### Scrub Behavior

- **With redundancy (mirror/RAID-Z)**: ZFS reads both copies, compares checksums, and repairs bad data automatically.
- **Without redundancy (stripe/RAID0)**: ZFS detects checksum mismatches but **cannot repair**. Reports "permanent errors."
- **Duration**: Depends on pool size and disk speed. An 8TB disk takes ~2-4 hours.

---

## 4. Verify File Integrity Manually

```bash
# Test if a "corrupted" file is actually readable
cat "/mnt/pool/dataset/path/to/file" > /dev/null 2>&1 && echo "READABLE" || echo "UNREADABLE"

# Calculate checksum outside ZFS (for comparison)
md5sum "/mnt/pool/dataset/path/to/file"
sha256sum "/mnt/pool/dataset/path/to/file"

# Check file type (detect truncation/corruption)
file "/mnt/pool/dataset/path/to/file"
```

If the file reads without I/O errors and plays/opens correctly, the live data is likely intact despite ZFS reporting historical checksum mismatches.

---

## 5. Check ZFS Checksum Algorithm

```bash
# View checksum algorithm for a dataset
zfs get checksum <pool>/<dataset>

# Common values:
# on (default) = fletcher4
# fletcher4, sha256, edonr, off
```

### Checksum Algorithms

| Algorithm | Speed | Collision Resistance | Use Case |
|-----------|-------|---------------------|----------|
| `fletcher4` (default) | Fast | Good | General purpose |
| `sha256` | Slower | Excellent | High-security environments |
| `edonr` | Fastest | Moderate | Performance-critical workloads |
| `off` | N/A | None | **Never use** (defeats ZFS integrity) |

**Note:** Changing checksum algorithm only affects *new* writes. Existing data retains its original checksums.

---

## 6. Clear Error State

```bash
# Reset all error counters for a pool
zpool clear <pool_name>

# Clear errors for a specific device
zpool clear <pool_name> <device>
```

**Warning:** This only clears the counter. It does **not** fix corrupted data. Only use after:
1. Confirming live files are readable
2. Restoring from backup
3. Accepting data loss

---

## 7. SMART Disk Health Checks

```bash
# Quick health assessment
smartctl -H /dev/sdX

# Full SMART data (look for Reallocated_Sector_Ct, Current_Pending_Sector)
smartctl -a /dev/sdX

# Run short self-test (~2 min)
smartctl -t short /dev/sdX

# Run extended self-test (~hours, depends on disk size)
smartctl -t long /dev/sdX

# View test results
smartctl -l selftest /dev/sdX
```

### Critical SMART Attributes

| ID | Attribute | Threshold | Action if Non-Zero |
|----|-----------|-----------|-------------------|
| 5 | Reallocated_Sector_Ct | 0 | Disk failing, replace immediately |
| 197 | Current_Pending_Sector | 0 | Bad sectors pending reallocation |
| 198 | Offline_Uncorrectable | 0 | Unrecoverable read errors |
| 199 | UDMA_CRC_Error_Count | 0 | Cable/controller issue |

---

## 8. Additional Diagnostic Commands

```bash
# View pool properties
zpool get all <pool_name>

# View dataset properties
zfs get all <pool>/<dataset>

# Check for ZFS events/errors in system log
dmesg | grep -i zfs
journalctl -k | grep -i zfs

# List all snapshots for a dataset
zfs list -t snapshot <pool>/<dataset>

# Check ARC (cache) usage
arc_summary
```

---

## 9. Recovery Decision Tree

```
ZFS reports checksum errors
│
├─ Is pool mirrored/RAID-Z?
│  ├─ YES → Run `zpool scrub`. ZFS auto-repairs.
│  └─ NO → Proceed below
│
├─ Are live files readable?
│  ├─ YES → Corruption likely historical/snapshot-only
│  │         → Clear errors, monitor next scrub
│  └─ NO → Data is genuinely corrupted
│           ├─ Have backup? → Restore files
│           └─ No backup? → Accept loss, delete files
│
└─ Are SMART attributes clean?
   ├─ YES → Likely bit rot/RAM issue
   │         → Run memtest, enable ECC if possible
   └─ NO → Hardware failure
            → Replace disk immediately
```

---

## 10. Prevention Best Practices

1. **Add redundancy** — Mirror or RAID-Z2 minimum for production data
2. **Schedule regular scrubs** — Weekly for critical pools, monthly for archives
   ```bash
   # Add to cron (TrueNAS has built-in scrub scheduling)
   0 2 * * 0 /sbin/zpool scrub <pool_name>
   ```
3. **Enable email alerts** — Configure SMART and ZFS event notifications
4. **Test backups regularly** — Verify restore capability quarterly
5. **Use ECC RAM** — Prevents memory-induced bit flips during writes
6. **Monitor SMART trends** — Set up Grafana/Zabbix for long-term disk health tracking
7. **Keep spare drives** — Reduce downtime when replacement is needed

---

## Quick Reference Cheat Sheet

```bash
# Health check one-liner
zpool status -v <pool> | head -20

# Find corrupted live files
zpool status -v <pool> | grep "^        /mnt/"

# Start scrub + monitor
zpool scrub <pool> && watch -n 5 zpool status <pool>

# Clear errors after verification
zpool clear <pool>

# Check disk health
for disk in sde sdg; do smartctl -H /dev/$disk; done
```