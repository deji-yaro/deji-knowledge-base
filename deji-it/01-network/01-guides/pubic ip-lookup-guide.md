# IP Lookup on Linux Using `asn`

A practical guide to looking up public IP address information from the terminal — including ASN, provider, hostname, and geolocation — using the `asn` tool by [nitefood](https://github.com/nitefood/asn).

---

## What is `asn`?

`asn` is a free, open-source bash script that queries multiple public data sources to give you a detailed breakdown of any public IP address. It returns:

- **IP** — the address being looked up
- **ASN** — Autonomous System Number (the routing identity of a network)
- **Provider / Organization** — who owns the IP block (ISP, cloud provider, etc.)
- **Hostname** — reverse DNS name for the IP
- **Geolocation** — estimated country, city, and coordinates
- **Reputation** — threat scoring and abuse contact info (requires optional API tokens)

It works entirely from the terminal with no GUI required, and it supports bulk lookups via stdin or file input.

---

## Step 1: Install Dependencies

`asn` relies on several standard Linux tools. Install them all at once:

```bash
sudo apt install curl whois dnsutils mtr jq ipcalc grepcidr nmap ncat aha
```

**What each dependency does:**

- `curl` — makes HTTP requests to external data APIs
- `whois` — queries WHOIS databases for ASN and IP ownership info
- `dnsutils` — provides `host` and `dig` for reverse DNS lookups
- `mtr` — used for traceroute functionality (optional but useful)
- `jq` — parses JSON responses from APIs
- `ipcalc` — calculates IP ranges and subnet masks
- `grepcidr` — filters IPs by CIDR notation
- `nmap` / `ncat` — used in server mode and port scanning
- `aha` — converts colored terminal output to HTML (used in server mode)

---

## Step 2: Download and Install `asn`

Download the script directly to `/usr/local/bin` so it's available system-wide:

```bash
sudo curl -o /usr/local/bin/asn https://raw.githubusercontent.com/nitefood/asn/master/asn
```

Then make it executable:

```bash
sudo chmod +x /usr/local/bin/asn
```

Verify the permissions look correct:

```bash
ls -la /usr/local/bin/asn
# Expected output: -rwxr-xr-x 1 root root ...
```

The `-rwxr-xr-x` means the file is executable by all users. If it shows `-rw-r--r--` (no `x`), the `chmod` step was missed — re-run it with `sudo`.

---

## Step 3: Set Up API Tokens

`asn` integrates with three optional external services to enrich its output. Without tokens, you will see this warning every time you run the tool:

```
────────────────────────────────────────────────────
Warning: At least one external API token is missing.
To enable full script functionalities, please visit
https://github.com/nitefood/asn#api-tokens
────────────────────────────────────────────────────
```

> **Important:** The script checks that all three token files exist AND contain content. Even if you only sign up for one service, you must create placeholder files for the others — otherwise the warning will persist.

### Create the token directory

```bash
mkdir -p ~/.asn
```

### Token 1: IPinfo (Recommended — Free)

IPinfo significantly improves geolocation accuracy. Without it, location data may be approximate or missing.

1. Sign up at [https://ipinfo.io/signup](https://ipinfo.io/signup) (no credit card required)
2. Copy your API token from the dashboard
3. Save it:

```bash
echo "your_ipinfo_token_here" > ~/.asn/ipinfo_token
```

### Token 2: IPQualityScore (Optional)

Adds threat intelligence — flags IPs as bots, proxies, or known malicious actors.

1. Sign up at [https://www.ipqualityscore.com](https://www.ipqualityscore.com)
2. Save your token:

```bash
echo "your_iqs_token_here" > ~/.asn/iqs_token
```

If you choose not to sign up, create a placeholder so the warning is silenced:

```bash
echo "none" > ~/.asn/iqs_token
```

### Token 3: Cloudflare Radar (Optional)

Adds BGP incident history — useful for detecting route hijacks and leaks.

1. Sign up at [https://developers.cloudflare.com](https://developers.cloudflare.com)
2. Save your token:

```bash
echo "your_cloudflare_token_here" > ~/.asn/cloudflare_token
```

Or use a placeholder:

```bash
echo "none" > ~/.asn/cloudflare_token
```

### Verify all token files exist

```bash
ls -la ~/.asn/
```

You should see three files: `ipinfo_token`, `iqs_token`, and `cloudflare_token`. All three must exist and contain at least some text.

---

## Step 4: Basic Usage

### Look up a single IP

```bash
asn 8.8.8.8
```

### Look up multiple IPs

```bash
asn 8.8.8.8 1.1.1.1 9.9.9.9
```

### Look up a hostname or domain

```bash
asn google.com
```

### Look up your own public IP

```bash
asn
```

Running `asn` with no arguments automatically detects and looks up your current public IP address.

### Bulk lookup from a file

```bash
cat ips.txt | asn
```

Where `ips.txt` contains one IP per line.

---

## Step 5: Save Output to a Markdown File

By default, all output stays in the terminal. To save it, you need to redirect it — but `asn` uses colored terminal output (ANSI escape codes) which must be stripped before saving, otherwise the file will contain garbage characters like `^[[0;32m`.

### Single IP to markdown

```bash
asn 8.8.8.8 | sed 's/\x1b\[[0-9;]*m//g' > report.md
```

### Multiple IPs with formatted markdown sections

```bash
{
  echo "# IP Lookup Report"
  echo "_Generated: $(date)_"
  echo ""
  for IP in 8.8.8.8 1.1.1.1 9.9.9.9; do
    echo "## $IP"
    echo '```'
    asn "$IP" | sed 's/\x1b\[[0-9;]*m//g'
    echo '```'
    echo ""
  done
} > report.md
```

---

## Step 6: Create a Reusable Lookup Script

Save this as `~/ip-lookup.sh` for convenient repeated use:

```bash
#!/bin/bash
# ip-lookup.sh — look up one or more public IPs and save results to markdown

if [ $# -eq 0 ]; then
  echo "Usage: ip-lookup.sh <IP1> <IP2> ..."
  echo "Example: ip-lookup.sh 8.8.8.8 1.1.1.1"
  exit 1
fi

OUTPUT="ip_report_$(date +%Y%m%d_%H%M%S).md"

{
  echo "# IP Lookup Report"
  echo "_Generated: $(date)_"
  echo ""
  for IP in "$@"; do
    echo "## $IP"
    echo '```'
    asn "$IP" | sed 's/\x1b\[[0-9;]*m//g'
    echo '```'
    echo ""
  done
} > "$OUTPUT"

echo "Saved to $OUTPUT"
```

Make it executable:

```bash
chmod +x ~/ip-lookup.sh
```

Run it:

```bash
~/ip-lookup.sh 8.8.8.8 1.1.1.1 9.9.9.9
# Output: Saved to ip_report_20250421_143022.md
```

Each run creates a timestamped file so previous reports are never overwritten.

---

## Understanding the Output

Here is what a typical `asn` result looks like and what each field means:

```
ASN lookup for 8.8.8.8
├── 8.8.8.8
│   ├── ASN       : AS15169
│   ├── Org       : Google LLC
│   ├── Hostname  : dns.google
│   ├── City      : Mountain View
│   ├── Region    : California
│   ├── Country   : United States
│   └── Coords    : 37.4056, -122.0775
```

| Field | What it means |
|---|---|
| **ASN** | Autonomous System Number — the unique identifier for a network/organization on the internet |
| **Org** | The organization or ISP that owns the IP block |
| **Hostname** | The reverse DNS record for the IP (what the IP "calls itself") |
| **City / Region / Country** | Estimated physical location — geolocation is approximate, not exact |
| **Coords** | Latitude and longitude of the estimated location |

> **Note on geolocation accuracy:** IP geolocation is an estimate based on registration data and network topology — not GPS. Results can be off by tens to hundreds of kilometers, especially for mobile IPs, VPNs, or cloud providers. Always treat city-level data as approximate.

---

## Common Issues and Fixes

### Permission denied when running `asn`

The script is missing its executable bit. Fix it with:

```bash
sudo chmod +x /usr/local/bin/asn
```

### Warning about missing API tokens persists

All three token files must exist and contain content (even placeholder text like `none`). Check:

```bash
ls ~/.asn/
cat ~/.asn/iqs_token
cat ~/.asn/cloudflare_token
```

If any file is missing or empty, recreate it:

```bash
echo "none" > ~/.asn/iqs_token
echo "none" > ~/.asn/cloudflare_token
```

### Lookup hangs on "Collecting pWhois data..."

The tool is trying to reach an external pWhois server which may be slow or temporarily unavailable. Wait up to 30 seconds or press `CTRL-C` to interrupt — the rest of the data will still be displayed.

### Saved markdown file contains garbled characters

You forgot to strip ANSI color codes. Always pipe through `sed` when saving:

```bash
asn 8.8.8.8 | sed 's/\x1b\[[0-9;]*m//g' > report.md
```

---

## Quick Reference

```bash
# Install dependencies
sudo apt install curl whois dnsutils mtr jq ipcalc grepcidr nmap ncat aha

# Install asn
sudo curl -o /usr/local/bin/asn https://raw.githubusercontent.com/nitefood/asn/master/asn
sudo chmod +x /usr/local/bin/asn

# Set up tokens
mkdir -p ~/.asn
echo "your_token" > ~/.asn/ipinfo_token
echo "none"       > ~/.asn/iqs_token
echo "none"       > ~/.asn/cloudflare_token

# Look up an IP
asn 8.8.8.8

# Save to markdown (strip colors)
asn 8.8.8.8 | sed 's/\x1b\[[0-9;]*m//g' > report.md
```
