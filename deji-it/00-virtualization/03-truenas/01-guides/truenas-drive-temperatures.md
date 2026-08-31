# How to List Drive Temperatures on TrueNAS SCALE

## Basic One-Liner

List temperatures for all detected drives at once:

```bash
sudo smartctl --scan | awk '{print $1}' | xargs -I{} sh -c 'echo -n "{}: "; sudo smartctl -A {} | grep -i "Temperature_Celsius" | awk "{print \$10\"°C\"}"'
```

---

## Recommended — With Timeout + NVMe Support (Handles All Drive Types)

Prevents the command from hanging if a drive is present on the bus but not responding, and correctly reads both HDD/SSD and NVMe temperatures:

```bash
sudo smartctl --scan | awk '{print $1}' | while read dev; do
  temp=$(sudo timeout 5 smartctl -A $dev | grep -iE "Temperature_Celsius|^Temperature:" | grep -oE "[0-9]+" | head -1)
  echo "$dev: ${temp:-UNREADABLE}°C"
done
```

- `timeout 5` — kills the query after 5 seconds if the drive doesn't respond
- `^Temperature:` — matches NVMe format (e.g. `Temperature: 43 Celsius`)
- `Temperature_Celsius` — matches HDD/SSD SMART attribute format
- `UNREADABLE` — printed instead of hanging when a drive is unresponsive

---

## NVMe Drives — What to Expect

NVMe drives report temperature differently from HDDs. Running `sudo smartctl -A /dev/nvme0` shows:

```
Temperature:                        43 Celsius
Temperature Sensor 1:               43 Celsius
Temperature Sensor 2:               47 Celsius
```

Note that NVMe drives may expose **multiple temperature sensors** — the loop command picks the first one (controller temp). To see all sensors for a specific NVMe:

```bash
sudo smartctl -A /dev/nvme0 | grep -i temp
```

### Other useful NVMe health fields to watch

| Field | What it means |
|---|---|
| `Critical Warning` | `0x00` = healthy, anything else needs attention |
| `Available Spare` | Should stay well above the `Available Spare Threshold` |
| `Unsafe Shutdowns` | High count may indicate power instability |
| `Media and Data Integrity Errors` | Should always be `0` |

---

## Single Drive (Original Method)

If you only need one specific drive:

```bash
sudo smartctl -a /dev/sda | grep -i temp
```

Replace `/dev/sda` with your target drive.

---

## Recommended Temperature Ranges

| Drive Type | Ideal | Acceptable | Warning | Critical — Act Immediately |
|---|---|---|---|---|
| HDD | 25–40°C | 40–50°C | 50–55°C | 55°C+ |
| SSD | 25–45°C | 45–55°C | 55–60°C | 60°C+ |
| NVMe | 30–50°C | 50–65°C | 65–75°C | 75°C+ |

- NVMe drives run naturally hotter than HDDs/SSDs — this is normal.
- Sustained temps in the **Warning** range will shorten drive lifespan significantly.
- If drives are running hot, check case airflow and ensure the NAS has adequate ventilation.

---

## Notes

- Drive names on TrueNAS follow `/dev/sda`, `/dev/sdb` ... `/dev/sdk` etc.
- NVMe drives appear as `/dev/nvme0`, `/dev/nvme1` etc. — the recommended loop command handles both.
- A drive that consistently hangs SMART queries is likely failing — check it in **TrueNAS UI → Storage → Disks** for reallocated sectors or SMART errors.
- A drive showing `UNREADABLE` that is not part of any pool should be investigated or replaced.
