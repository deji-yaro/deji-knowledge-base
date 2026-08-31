# Maigret — Email OSINT Lookup Guide

## ⚠️ Disclaimer

This guide is intended for **legal, authorized security research and OSINT investigations only**. Always ensure you have proper authorization before conducting lookups on any individual or organization. Unauthorized use of these techniques may violate local and international laws. The use of proxies, VPNs, or Tor to perform lookups should comply with the terms of service of the sites being queried and the laws of your jurisdiction.

---

## Installation

```bash
pip3 install maigret --break-system-packages
```

### Fix PATH issue (if `maigret: command not found`):
```bash
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
```

---

## Basic Usage

```bash
maigret target@email.com
```

By default, maigret searches the **top 510 sites** from its database of 3000+ sites.

---

## Search All Available Sites

```bash
maigret target@email.com -a
```

Searches all **2492+ sites** — takes around 2-3 minutes.

---

## Show Detailed Errors

```bash
maigret target@email.com -a --print-errors
```

---

## Reduce Parallel Connections (fix connection failures)

```bash
maigret target@email.com -a -n 10
```

---

## Output Reports

| Flag | Format |
|---|---|
| `-T` | TXT |
| `-C` | CSV |
| `-H` | HTML |
| `-X` | XML |
| `-P` | PDF |
| `-M` | Markdown |
| `-G` | Graph |

```bash
# Save as TXT to a custom folder
maigret target@email.com -a -T --folderoutput ~/results/

# Save as Markdown
maigret target@email.com -a -M --folderoutput ~/results/
```

---

## Using Tor as a Proxy

> ⚠️ **Proxy/VPN Disclaimer**: Routing traffic through Tor or a proxy may help bypass IP-based blocks, but many major sites actively block known Tor exit nodes and free proxy IPs. Use residential proxies for better results. Always ensure proxy usage complies with applicable laws and site terms of service.

### Start Tor
```bash
sudo service tor start
```

### Verify Tor is working
```bash
curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
```
Should return `"IsTor":true`.

### Run maigret through Tor
```bash
maigret target@email.com -a --tor-proxy socks5://127.0.0.1:9050
```

---

## Using a Custom Proxy

```bash
maigret target@email.com -a --proxy socks5://PROXY_IP:PORT
```

Free proxy lists:
- `proxyscrape.com`
- `spys.one`
- `github.com/TheSpeedX/PROXY-List`

---

## Using ProxyChains (Kali built-in)

```bash
# Edit proxychains config and add your proxies
sudo nano /etc/proxychains4.conf

# Run maigret through proxychains
proxychains maigret target@email.com -a
```

---

## Using Session Cookies (bypass some blocks)

```bash
maigret target@email.com -a --cookies-jar-file cookies.txt
```

Export cookies from your browser using an extension like **Cookie-Editor**.

---

## Full Recommended Command

```bash
sudo service tor start
maigret target@email.com -a --tor-proxy socks5://127.0.0.1:9050 -n 10 --retries 3 --timeout 30 --print-errors -T --folderoutput ~/results/
```

---

## Transfer Results via SCP

```bash
scp ~/results/report_target@email.com.txt user@REMOTE_IP:~/Desktop/
```

### Transfer entire results folder
```bash
scp -r ~/results/ user@REMOTE_IP:~/Desktop/
```

### Alternative — Python HTTP server
```bash
cd ~/results/
python3 -m http.server 8080
# Then open http://KALI_IP:8080 in a browser on the remote machine
```

---

## Understanding Errors

| Error | Cause | Fix |
|---|---|---|
| `Unsupported username format` | Site doesn't support email format | Nothing — unavoidable |
| `Access denied (403)` | Site blocking your IP | Use Tor / proxy |
| `Bot protection / Cloudflare` | Anti-bot challenge | Rotate Tor exit node or use residential proxy |
| `Connecting failure` | Too many parallel connections | Use `-n 10` |
| `Misformatted domain name` | Site uses username-as-subdomain | Nothing — email limitation |

---

*Guide based on Maigret v0.6.0 — Kali Linux*
