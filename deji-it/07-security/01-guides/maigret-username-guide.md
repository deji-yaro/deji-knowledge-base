# Maigret OSINT Guide

Maigret is a powerful username-hunting tool that searches 3000+ sites and extracts profile data — a significant upgrade over Sherlock.

---

## Installation

### Option 1: pip (recommended)
```bash
pip install maigret
```

### Option 2: pipx (isolated environment)
```bash
pipx install maigret
```

### Option 3: From source (latest dev version)
```bash
git clone https://github.com/soxoj/maigret
cd maigret
pip install .
```

### Option 4: Docker
```bash
docker pull soxoj/maigret
docker run soxoj/maigret username
```

**Requirements:** Python 3.10+

---

## Basic Usage

```bash
# Search a username (top ~509 sites)
maigret username

# Search ALL 3000+ sites
maigret username -a
```

---

## Output / Reports

Maigret saves reports automatically to a `reports/` folder. If you're running from source, use explicit flags to ensure files are saved:

```bash
# Recommended command — full search + txt output
maigret username -a --txt --folderoutput reports/

# Full search + all formats
maigret username -a --txt --pdf --html --folderoutput $(pwd)/reports/
```

### Output format flags

| Flag | Output |
|------|--------|
| `--txt` | Plain text report |
| `--html` | HTML report |
| `--pdf` | PDF report |
| `--csv` | CSV (not saved by default) |
| `--json` | JSON (not saved by default) |

---

## Useful Flags

| Flag | Description |
|------|-------------|
| `-a` | Search all 3157 sites (slower but thorough) |
| `--txt` | Save results as .txt |
| `--pdf` | Save results as .pdf |
| `--html` | Save results as .html |
| `--folderoutput <dir>` | Set output directory |
| `--print-errors` | Show detailed errors for failed site checks |
| `--tor` | Route requests through Tor |
| `--proxy <url>` | Use a proxy |

---

## Troubleshooting

### Reports folder is empty
If running from source, use `--folderoutput` with an absolute path:
```bash
maigret username -a --txt --folderoutput $(pwd)/reports/
```

### Too many "Unexpected" errors
Run with `--print-errors` to see what's failing:
```bash
maigret username --print-errors
```
Some sites block automated requests — this is normal. Errors above ~30% may indicate rate limiting or network issues.

### Permission errors (Linux/macOS)
```bash
pip install --user maigret
```

---

## Example Output

A successful search returns found accounts with extracted metadata:

```
[+] YouTube: https://www.youtube.com/@username/about
        ├─fullname: John Doe
        ├─youtube_channel_id: UC_xxxxxxxxxxxx
        └─is_family_safe: True

[+] Duolingo: https://www.duolingo.com/profile/username
        ├─uid: 123456789
        ├─created_at: 2022-05-09 11:53:08 UTC
        ├─learningLanguage: ja
        └─totalXp: 7599
```

---

## Tips

- Always run with `-a` for the most complete results — the default only checks ~509 of 3157 sites.
- Maigret auto-updates its site database on each run.
- Combine `--tor` with `-a` for anonymous full searches (slower).
- Cross-reference found usernames recursively — a YouTube name may differ from a Reddit name found in the bio.
- False positives do occur; always manually verify found profiles.

---

## Resources

- GitHub: https://github.com/soxoj/maigret
- Site list: https://github.com/soxoj/maigret/blob/main/sites.md
