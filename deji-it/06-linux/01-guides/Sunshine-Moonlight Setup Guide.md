## Overview
Sunshine is a self-hosted game stream host that allows you to stream your PC games to Moonlight clients. This guide covers installation, configuration, and optimal network requirements.

---

## Part 1: Host Installation (Sunshine)

### System Requirements
- **Ubuntu 24.04** (or similar Linux distribution)
- **GPU with hardware encoding support:**
  - NVIDIA: NVENC (GTX 600 series or newer)
  - AMD: VAAPI or AMF
  - Intel: QuickSync or VAAPI
- **Network:** Wired Ethernet recommended (WiFi 5GHz minimum)

### Installation on Ubuntu

#### Method 1: Download .deb Package
```bash
# Download the latest release
wget https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-ubuntu-24.04-amd64.deb

# Install with dpkg
sudo dpkg -i sunshine-ubuntu-24.04-amd64.deb

# Fix any dependency issues
sudo apt --fix-broken install
#### Method 2: Install Missing Dependencies
```bash
sudo apt update
sudo apt install miniupnpc libminiupnpc17
```

### Starting Sunshine
```bash
# Start Sunshine service
sudo systemctl start sunshine

# Enable to start on boot
sudo systemctl enable sunshine

# Check status
sudo systemctl status sunshine
```

### Accessing the Web Interface
- **URL:** `http://localhost:47990`
- **Default Credentials:**
  - Username: (leave blank)
  - Password: (auto-generated, shown in terminal logs)

To retrieve the password:
```bash
sudo journalctl -u sunshine | grep -i "password"
```

---

## Part 2: Client Installation (Moonlight)

### Supported Devices
- **Android** (phones, tablets, Android TV)
- **iOS** (iPhone, iPad)
- **Windows** (desktop application)
- **macOS** (desktop application)
- **Linux** (Flatpak or AppImage)
- **Smart TVs** (Samsung, LG, etc. via app stores)
- **Fire TV Stick, NVIDIA Shield, Chromecast**

### Installation

#### On Android/Android TV
1. Open **Google Play Store**
2. Search for **"Moonlight Game Streaming"**
3. Install the official app

#### On Windows/macOS/Linux
1. Visit [Moonlight Streaming](https://moonlight-stream.org)
2. Download the appropriate version
3. Install following platform-specific instructions

### Pairing Moonlight with Sunshine

1. Open Moonlight on your client device
2. The app should automatically discover your Sunshine host
   - If not, manually enter your PC's IP address
3. **Authentication:**
   - Moonlight will display a 4-digit PIN
   - On the Sunshine Web UI, go to **Configuration → Authentication**
   - Enter the PIN and click **"Pair"**
4. Once paired, you'll see your PC's applications

---

## Part 3: Network Requirements

### Recommended Network Setup

#### Minimum Requirements
| Parameter | Requirement |
|-----------|-------------|
| **Bandwidth** | 10 Mbps minimum |
| **Latency** | < 30ms (local network) |
| **WiFi Standard** | 802.11ac (WiFi 5) or better |
| **WiFi Band** | 5 GHz (avoid 2.4 GHz) |
| **Connection Type** | Wired Ethernet preferred |

#### Optimal Settings
| Parameter | Recommendation |
|-----------|---------------|
| **Bandwidth** | 50+ Mbps |
| **Latency** | < 10ms |
| **Router** | WiFi 6 (802.11ax) |
| **Cabling** | Cat5e or Cat6 Ethernet |

### Network Optimization

#### WiFi Optimization
```bash
# Check your WiFi link speed
iwconfig

# Check for network interference
sudo iwlist wlan0 scan | grep -i "channel\|frequency"
```

#### QoS (Quality of Service)
- Enable QoS on your router
- Prioritize gaming/streaming traffic
- Set bandwidth limits for other devices

#### Ports Required
Sunshine uses these ports:
| Port | Protocol | Purpose |
|------|----------|---------|
| 47984 | TCP | Control |
| 47989 | TCP | Streaming |
| 47990 | TCP | Web UI |
| 47998-48010 | UDP | Video/Audio |

---

## Part 4: Configuration Settings

### Sunshine Web Interface Settings

#### Audio/Video Tab
| Setting | Description |
|---------|-------------|
| **Resolution** | Stream resolution (720p, 1080p, 4K) |
| **FPS** | Frames per second (30, 60, 120) |
| **Bitrate** | Target bitrate in kbps |
| **Codec** | H.264 or HEVC (H.265) |

#### Advanced Tab
| Setting | Description |
|---------|-------------|
| **Encoder** | Force specific GPU encoder |
| **FEC Percentage** | Forward Error Correction |
| **Frame Pacing** | Smooth frame delivery |
| **GPU Performance Mode** | Maximum performance mode |

### Configuration File Location
```bash
~/.config/sunshine/sunshine.conf
```

### Common Configuration Lines
```ini
# Encoder selection
encoder = nvenc        # NVIDIA
encoder = vaapi        # Intel/AMD
encoder = amf          # AMD
encoder = software     # CPU

# Bitrate settings
bitrate = 20000        # 20 Mbps
max_bitrate = 20000    # Limit

# Quality settings
fps = 60
qp = 23                # Quality (lower = better)
fec_percentage = 0     # Disable FEC

# AMD specific
vaapi_preset = 0
vaapi_quality = 1
```

---

## Part 5: Moonlight Client Settings

### Recommended Settings
| Setting | Value |
|---------|-------|
| **Resolution** | Match host or 1080p |
| **FPS** | 60 (or match host) |
| **Bitrate** | 15-25 Mbps |
| **Video Codec** | H.264 (most compatible) |
| **Frame Pacing** | Prefer Smooth Video |
| **Audio** | Stereo (instead of 5.1) |
| **Controller** | Xbox or Steam |

### Settings to Avoid
- **"Prefer Lowest Latency"** - Causes stutter on slower clients
- **"Auto" bitrate** - Can be inconsistent
- **HEVC (H.265)** - More processing required

---

## Part 6: Verification

### Check Sunshine is Running
```bash
sudo systemctl status sunshine
```

### Check Encoder Support
```bash
# NVIDIA
nvidia-smi

# Intel/AMD VAAPI
vainfo

# Check Sunshine logs
sudo journalctl -u sunshine -f
```

### Network Speed Test
```bash
# Install iperf3
sudo apt install iperf3

# On host (server mode)
iperf3 -s

# On client (run this)
iperf3 -c [HOST_IP_ADDRESS]
```

---

## File Locations

### Sunshine
| Item    | Path                                   |
| ------- | -------------------------------------- |
| Config  | `~/.config/sunshine/sunshine.conf`     |
| Logs    | `~/.cache/sunshine/sunshine.log`       |
| Service | `/etc/systemd/system/sunshine.service` |

### Moonlight (Flatpak)
| Item | Path |
|------|------|
| Data | `~/.var/app/[APP_ID]/` |
| Config | `~/.var/app/[APP_ID]/config/` |
| Saves | `~/.var/app/[APP_ID]/data/` |

---
