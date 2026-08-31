# 🖨️ Brother Scanner on Linux — Complete Guide
### Ubuntu · Debian · Mint — From Zero to Scanning

> **Based on real-world troubleshooting of Brother MFC-J880DW and MFC-J1010DW over Wi-Fi.**  
> Everything here has been tested and verified to work.

---

## 📋 Table of Contents

1. [How It Works — The Big Picture](#1-how-it-works)
2. [Step 1 — Install the Brother Driver](#2-install-the-brother-driver)
3. [Step 2 — Register the Scanner on the Network](#3-register-the-scanner)
4. [Step 3 — Verify with Baremetal Test](#4-baremetal-test)
5. [Step 4 — Choose a Scanning App](#5-scanning-apps)
6. [Troubleshooting — Stale Devices](#6-stale-devices)
7. [Troubleshooting — Permissions](#7-permissions)
8. [Troubleshooting — Firewall](#8-firewall)
9. [Troubleshooting — 32-bit Libraries](#9-32-bit-libraries)
10. [Troubleshooting — Wrong brscan Version](#10-wrong-brscan-version)
11. [Troubleshooting — Color vs Mono](#11-color-vs-mono)
12. [Scanning from the Terminal](#12-terminal-scanning)
13. [Physical Scan Button (brscan-skey)](#13-scan-button)
14. [Keeping It Working Long-Term](#14-long-term)
15. [Quick Reference Cheatsheet](#15-cheatsheet)

---

## 1. How It Works — The Big Picture

Brother scanners on Linux rely on two separate layers:

- **The SANE backend** (`brscan4`, `brscan5`, etc.) — the driver that lets Linux talk to the scanner hardware.
- **A scanning app** (`simple-scan`, `NAPS2`, etc.) — the user interface that talks to SANE.

The driver is **not** the same as the print driver. You can print fine and still have a completely broken scan setup. You need to install the **brscan** package specifically.

For **network/Wi-Fi scanners**, there is a third piece: you must manually tell the driver the **IP address** of your scanner using the `brsaneconfig` tool. The scanner will never be auto-discovered reliably over a network.

---

## 2. Step 1 — Install the Brother Driver

### Find Your Model's Driver

Go to [support.brother.com](https://support.brother.com), search for your model, and select **Linux**. Download the **Driver Install Tool** (a `.gz` file).

### Run the Installer

```bash
# Decompress the tool
gunzip linux-brprinter-installer-*.gz

# Run it (replace YOUR_MODEL_NAME with e.g. MFC-J1010DW)
sudo bash linux-brprinter-installer-* YOUR_MODEL_NAME
```

This installs both the print driver and the correct `brscan` package for your model family.

### Which brscan Version Does My Model Use?

| brscan version | Typical models |
|---|---|
| `brscan2` | Very old models (pre-2010) |
| `brscan3` | Mid-range models (~2010–2014) |
| `brscan4` | Most models 2015–2020 (e.g. MFC-J880DW) |
| `brscan5` | Newer models 2020+ (e.g. MFC-J1010DW) |

To check which version was installed:

```bash
dpkg -l | grep brscan
```

---

## 3. Step 2 — Register the Scanner on the Network

This is the step most guides skip and the #1 reason scanning doesn't work over Wi-Fi.

### Find Your Printer's IP Address

Check your printer's LCD menu under **Network Settings → WLAN → IP Address**, or log into your router and look at the DHCP client list.

### Register the Scanner

Replace `brsaneconfig5` with the version that matches your installed driver. Replace `YOUR_MODEL_NAME` and `192.168.x.xx` with your actual values.

```bash
# For brscan5 models (e.g. MFC-J1010DW)
sudo brsaneconfig5 -a name=Brother_Scanner model=MFC-J1010DW ip=192.168.x.xx

# For brscan4 models (e.g. MFC-J880DW)
sudo brsaneconfig4 -a name=Brother_Scanner model=MFC-J880DW ip=192.168.x.xx
```

### Verify the Registration

```bash
# List all registered brscan5 devices
sudo brsaneconfig5 -q

# List all registered brscan4 devices
sudo brsaneconfig4 -q
```

---

## 4. Step 3 — Verify with a Baremetal Test

Before opening any app, confirm the driver and network registration are working using the terminal. This eliminates GUI bugs from the equation.

### List All Detected Scanners

```bash
scanimage -L
```

Expected output (example):
```
device 'brother5:net1;dev0' is a Brother MFC-J1010DW
```

If your device appears here, the driver is correctly installed and registered. If nothing appears, go to [Troubleshooting — Stale Devices](#6-stale-devices).

### Run a Test Scan

```bash
# Test against a specific device
scanimage -T -d "brother5:net1;dev0"
```

**Interpreting the result:**

| Output | Meaning |
|---|---|
| `sane_start: Document feeder out of documents` | ✅ **Success** — driver talks to scanner, just needs paper |
| Command hangs with no output | ❌ Stale/wrong IP, or firewall blocking |
| `No devices found` | ❌ Driver not installed or not registered |
| `Invalid argument` | ❌ Wrong brsan version or model name mismatch |

> **"Document feeder out of documents" is a good error.** It means the handshake worked — just put paper in and scan.

---

## 5. Step 4 — Choose a Scanning App

Once the baremetal test passes, any of these apps will work.

### Document Scanner / Simple Scan (Default on Ubuntu/GNOME)

```bash
sudo apt install simple-scan
```

Clean and minimal. Good for quick PDF or image scans. Go to **Preferences** to select the correct device if it doesn't auto-detect.

> ⚠️ Make sure the mode in the top-left is set to **Image** (not **Text**) if you want color scans.

### NAPS2 — Recommended for Power Users

NAPS2 supports OCR, batch scanning, and lets you choose between **SANE** and **ESCL** (driverless) protocols — making it the most robust option.

```bash
# Download and install
wget https://www.naps2.com/download/naps2-latest-linux-x64.deb
sudo apt install ./naps2-latest-linux-x64.deb
```

In NAPS2: go to **Profiles → New** and try **SANE Driver** first. If it hangs, switch to **ESCL Driver** — many modern Brother printers support this driverless protocol.

### Skanpage (KDE / Kubuntu)

```bash
sudo apt install skanpage
```

Lean and stable. Best choice if you are on a KDE-based desktop.

### XSane / Skanlite (Power User / Technical)

```bash
sudo apt install xsane
# or
sudo apt install skanlite
```

Use these when you need fine-grained control over gamma, bit depth, or color profiles.

### VueScan (Paid — Last Resort)

If your Brother model is very old and the official drivers no longer exist, [VueScan](https://www.hamrick.com) bundles its own drivers and supports almost every Brother scanner ever made.

---

## 6. Troubleshooting — Stale Devices

**Symptom:** `scanimage -L` shows devices, but `scanimage -T` hangs indefinitely.

This happens when old scanner entries point to IPs that no longer exist. SANE tries to poll them and hangs waiting for a timeout.

### Remove Stale Entries

```bash
# Remove a stale brscan4 device by its registered name
sudo brsaneconfig4 -r MFC-J880DW

# Remove a stale brscan5 device by its registered name
sudo brsaneconfig5 -r deji-bro
```

### Verify They Are Gone

```bash
scanimage -L
```

The list should now be empty (or show only local backends like `escl`).

### Re-add the Correct Device

```bash
sudo brsaneconfig5 -a name=Brother_Scanner model=MFC-J1010DW ip=192.168.x.xx
```

Then re-run the baremetal test:

```bash
scanimage -T -d "brother5:net1;dev0"
```

---

## 7. Troubleshooting — Permissions

**Symptom:** Scanning works with `sudo` but fails as a normal user. The app sees the scanner but clicking Scan does nothing or returns an error.

Linux restricts hardware access to specific groups. If your user isn't in the `scanner` or `lp` group, the app can detect the scanner's presence but can't communicate with it.

### Add Your User to the Required Groups

```bash
sudo usermod -aG scanner,lp $USER
```

**You must log out and log back in** (or reboot) for this to take effect.

### Quick Test to Confirm It's a Permission Issue

```bash
# If this works but the GUI app doesn't, it's a permissions problem
sudo simple-scan
```

---

## 8. Troubleshooting — Firewall

**Symptom:** Scanner is on Wi-Fi, baremetal test hangs, but pinging the printer works fine.

Brother network scanners use specific **UDP ports** to communicate. If `ufw` (Uncomplicated Firewall) is active, it may be silently dropping these packets.

### Quick Test — Disable Firewall Temporarily

```bash
sudo ufw disable
```

Then retry `scanimage -T`. If it works now, the firewall was the issue.

### Permanent Fix — Open the Required Ports

```bash
sudo ufw allow proto udp from any to any port 54921,54925
sudo ufw enable
```

### Verify Firewall Status

```bash
sudo ufw status verbose
```

---

## 9. Troubleshooting — 32-bit Libraries

**Symptom:** Driver installer runs without errors, but `scanimage -L` shows nothing, or scanning silently fails on a 64-bit system.

Brother's scanner drivers are built on 32-bit architecture. On a 64-bit Ubuntu/Debian system, the driver may fail silently without the legacy 32-bit `libusb` library.

### Install the Missing Library

```bash
sudo apt update
sudo apt install libusb-0.1-4:i386
```

Then retry:

```bash
scanimage -L
```

---

## 10. Troubleshooting — Wrong brscan Version

**Symptom:** `scanimage -L` shows the scanner, but `scanimage -T` returns `Invalid argument` or the scanner shows in the wrong format (e.g., `brother4` for a model that needs `brother5`).

### Check Which Versions Are Installed

```bash
dpkg -l | grep brscan
```

### Re-register Using the Correct Version

If you registered with `brsaneconfig4` but the driver is `brscan5`, remove and re-add:

```bash
# Remove from wrong version
sudo brsaneconfig4 -r Brother_Scanner

# Add with correct version
sudo brsaneconfig5 -a name=Brother_Scanner model=MFC-J1010DW ip=192.168.x.xx
```

### Check Available Config Tools

```bash
which brsaneconfig4
which brsaneconfig5
```

---

## 11. Troubleshooting — Color vs Mono

**Symptom:** Scans come out in black and white even though you want color.

The printer's physical **Mono/Color** button does **not** control scans initiated from the computer. The app or command sends its own mode instruction.

### In Simple Scan / Document Scanner

The mode selector in the top-left of the window controls color:
- **Text** = monochrome (forced, regardless of document)
- **Image** = full color

Make sure **Image** is selected before scanning.

### In the Terminal (scanimage)

Check available modes for your device:

```bash
scanimage -d "brother5:net1;dev0" --help | grep -A5 "mode"
```

Then scan in color explicitly:

```bash
scanimage -d "brother5:net1;dev0" --mode "Color" --format=png > color_scan.png
```

### In NAPS2

When creating a profile, set **Color Mode** to `24-bit Color` to hard-code it into that profile permanently.

---

## 12. Scanning from the Terminal

Full control over every scan parameter without any GUI.

### List All Available Devices

```bash
scanimage -L
```

### See All Options for Your Device

```bash
scanimage -d "brother5:net1;dev0" --help
```

### Basic Scan to PNG

```bash
scanimage -d "brother5:net1;dev0" --format=png > scan.png
```

### Scan in Color

```bash
scanimage -d "brother5:net1;dev0" --mode "Color" --format=png > color_scan.png
```

### Scan from Flatbed (not ADF)

```bash
scanimage -d "brother5:net1;dev0" --source "Flatbed" --mode "Color" --format=png > flatbed_scan.png
```

### Scan to PDF (via ImageMagick)

```bash
scanimage -d "brother5:net1;dev0" --mode "Color" --format=png > scan.png
convert scan.png scan.pdf
```

### Scan with Custom Resolution (DPI)

```bash
scanimage -d "brother5:net1;dev0" --mode "Color" --resolution 300 --format=png > scan_300dpi.png
```

### Batch Scan (Multiple Pages from ADF)

```bash
scanimage -d "brother5:net1;dev0" --batch=page%d.png --batch-count=10 --source "Automatic Document Feeder"
```

---

## 13. Physical Scan Button (brscan-skey)

Brother provides a utility called `brscan-skey` that lets you press the **Scan** button on the physical machine and have it automatically send the file to a folder on your Linux PC.

### Install

```bash
# Usually bundled with the Brother driver install tool
# If missing, download from support.brother.com for your model
```

### Start the Service

```bash
brscan-skey
```

### Auto-start on Boot

Add `brscan-skey` to your desktop environment's **Startup Applications**, or create a systemd user service:

```bash
# Create the service file
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/brscan-skey.service <<EOF
[Unit]
Description=Brother Scanner Key Tool

[Service]
ExecStart=/usr/bin/brscan-skey
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# Enable and start it
systemctl --user enable brscan-skey
systemctl --user start brscan-skey
```

---

## 14. Keeping It Working Long-Term

### Set a Static IP for Your Printer

The most common reason scanning randomly breaks is that the printer gets a **new IP address** from the router after a reboot. Fix this permanently:

- Log into your **router admin panel** (usually `192.168.1.1` or `192.168.0.1`)
- Find **DHCP Reservation** or **Static DHCP**
- Assign a fixed IP to your printer's MAC address

Once done, you'll never need to re-run `brsaneconfig` again.

### If the IP Does Change — Update the Registration

```bash
# Remove old entry
sudo brsaneconfig5 -r Brother_Scanner

# Re-add with new IP
sudo brsaneconfig5 -a name=Brother_Scanner model=MFC-J1010DW ip=NEW.IP.HERE
```

### Flush DNS if Hostname Resolution Breaks

```bash
sudo resolvectl flush-caches
```

---

## 15. Quick Reference Cheatsheet

```bash
# --- INSTALL ---
gunzip linux-brprinter-installer-*.gz
sudo bash linux-brprinter-installer-* MODEL_NAME

# --- REGISTER (choose your brscan version) ---
sudo brsaneconfig5 -a name=Brother model=MFC-J1010DW ip=192.168.x.xx
sudo brsaneconfig4 -a name=Brother model=MFC-J880DW  ip=192.168.x.xx

# --- LIST & VERIFY ---
sudo brsaneconfig5 -q          # list registered brscan5 devices
dpkg -l | grep brscan          # check installed brscan versions
scanimage -L                   # list all SANE-visible scanners

# --- BAREMETAL TEST ---
scanimage -T -d "brother5:net1;dev0"

# --- SCAN (terminal) ---
scanimage -d "brother5:net1;dev0" --mode "Color" --format=png > scan.png
scanimage -d "brother5:net1;dev0" --source "Flatbed" --mode "Color" --format=png > scan.png

# --- REMOVE STALE DEVICES ---
sudo brsaneconfig4 -r DEVICE_NAME
sudo brsaneconfig5 -r DEVICE_NAME

# --- PERMISSIONS ---
sudo usermod -aG scanner,lp $USER   # then log out & back in

# --- FIREWALL ---
sudo ufw allow proto udp from any to any port 54921,54925

# --- 32-BIT LIBRARY FIX ---
sudo apt install libusb-0.1-4:i386

# --- FLUSH DNS ---
sudo resolvectl flush-caches
```

---

*Guide compiled from live troubleshooting — Ubuntu 22.04+, Brother MFC-J880DW (brscan4) and MFC-J1010DW (brscan5) over Wi-Fi.*
