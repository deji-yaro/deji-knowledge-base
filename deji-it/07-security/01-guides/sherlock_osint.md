# Sherlock — Username OSINT Framework

## What is Sherlock?

Sherlock is an open-source OSINT tool that searches for a username across **300+ social media platforms** simultaneously. It is one of the most beginner-friendly tools available in Kali Linux and is widely used by security researchers, penetration testers, and investigators.

---

## Installation

### Method 1 — From Source (Recommended)
```bash
git clone https://github.com/sherlock-project/sherlock.git
cd sherlock
pip install -r requirements.txt
```

### Method 2 — Via APT
```bash
sudo apt update
sudo apt install sherlock -y
```

---

## Basic Usage

```bash
# Search single username
sherlock johndoe

# Search multiple usernames at once
sherlock johndoe janedoe john123

# Only show found accounts (cleaner output)
sherlock johndoe --print-found

# Save results to a text file
sherlock johndoe --output results.txt

# Save as CSV
sherlock johndoe --csv

# Save as XLSX
sherlock johndoe --xlsx
```

---

## Useful Flags

| Flag | Description |
|---|---|
| `--print-found` | Only show found results, cleaner output |
| `--output <file>` | Save results to a text file |
| `--csv` | Export results to CSV format |
| `--xlsx` | Export results to Excel format |
| `--timeout 10` | Set request timeout in seconds |
| `--tor` | Route requests through Tor for anonymity |
| `--unique-tor` | New Tor circuit per request |
| `--proxy <url>` | Use a specific proxy |
| `--site <name>` | Check a specific site only |

---

## Understanding the Output

```
[*] Checking username johndoe on:
[+] GitHub:       https://github.com/johndoe       ← FOUND
[+] Instagram:    https://instagram.com/johndoe     ← FOUND
[-] Twitter:      https://twitter.com/johndoe       ← NOT FOUND
```

| Symbol | Meaning |
|---|---|
| `[+]` | Account found on this platform |
| `[-]` | Account not found |
| `[*]` | Currently checking |

---

## Limitations — False Positives

Sherlock checks if a **URL returns a valid HTTP response**, not whether the profile actually exists. This leads to **false positives** — a common issue where Sherlock marks a profile as found when it is not.

### Why False Positives Happen

- The site returns HTTP 200 for all usernames regardless of existence
- The profile was deleted but the URL is still cached
- The page loads but displays a "user not found" message internally

### Real World Example

```
Sherlock reports → discords.com/unlawfulajay as FOUND
API check returns → {"error": "User not found"}
```

Sherlock saw a valid HTTP response — the API did a deeper database lookup and found nothing.

### How to Verify Results

Always **manually visit** the URL Sherlock returns:
1. Does it show an actual profile with content?
2. Or does it show a "not found" / empty page?

Manual verification is always the final confirmation step. **Sherlock is a starting point, not a definitive answer.**

---

## Using Sherlock for Identity Correlation

Sherlock becomes powerful when combined with other OSINT techniques. Finding the same username across multiple platforms builds confidence that you are looking at the same person.

### Confidence Stacking

```
Username found on 1 platform     → Low confidence
Username found on 3+ platforms   → Medium confidence
Username + consistent photo      → High confidence
Username + photo + location      → Very high confidence
```

### Workflow

```
1. Find a username from any public profile
2. Run Sherlock on that username
3. Visit found profiles manually to verify
4. Cross reference consistent details:
   └── Same profile photo
   └── Same location/employer
   └── Same writing style
5. Feed confirmed email/username into SpiderFoot for deeper scan
```

---

## Ethical and Legal Use

Sherlock should only be used on:

| ✅ Acceptable | ❌ Not Acceptable |
|---|---|
| Your own username | Stalking or harassing individuals |
| With explicit written permission | Aggregating data to cause harm |
| CTF and practice lab targets | Any unauthorized investigation |
| TryHackMe OSINT challenges | Violating platform terms of service |

---

## Integration With Other Tools

| Tool | How it complements Sherlock |
|---|---|
| `SpiderFoot` | Automates deeper correlation on found usernames |
| `Maltego` | Visually maps relationships between found accounts |
| `theHarvester` | Finds associated emails from discovered platforms |
| `EmailRep.io` | Checks reputation of emails found via Sherlock |
| `HaveIBeenPwned` | Checks breach history of associated emails |

---

## Practice Resources

- **TryHackMe** — guided OSINT rooms, browser based, beginner friendly
- **HackTheBox** — more advanced OSINT challenges
- **Your own username** — always a safe and legal starting point

---

*Document based on practical session covering Sherlock installation, usage, false positive handling, and integration into a broader OSINT workflow on Kali Linux WSL.*
