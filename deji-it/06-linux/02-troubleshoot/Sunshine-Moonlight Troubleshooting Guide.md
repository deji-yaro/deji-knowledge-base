
This guide covers common issues and solutions encountered when setting up Sunshine and Moonlight streaming.

## Issue 1: Dependency Errors During Installation
### Symptoms
* dpkg: dependency problems prevent configuration of sunshine:
* sunshine depends on miniupnpc; however: 
* Package miniupnpc is not installed.

### Solution
```

### Solution
```bash
# Install missing dependencies
sudo apt update
sudo apt install miniupnpc libminiupnpc17

# Or use apt fix
sudo apt --fix-broken install

# Alternative: Install directly with apt
sudo apt install ./sunshine-ubuntu-24.04-amd64.deb

```
## Issue 2: Application Launches on PC but Not Visible on TV

### Symptoms
- Sunshine launches the app on the host PC
- Moonlight client shows black screen or nothing
- App appears on PC monitor but not on stream

### Causes
- Flatpak sandboxing issues
- Wrong display selection
- App using different display context

### Solutions

#### Find Flatpak Executable
```bash
# List Flatpak contents
flatpak run --command=ls [APP_ID] /app/bin/

# Get app info
flatpak info [APP_ID]

# Example for PCSX2
flatpak run --command=/app/bin/pcsx2-qt net.pcsx2.PCSX2
```

#### Create Wrapper Script
```bash
cat > ~/app-launcher.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/$(id -u)
flatpak run --command=/app/bin/executable-name [APP_ID] "$@"
EOF

chmod +x ~/app-launcher.sh
```

#### Install Native Version
```bash
# Remove Flatpak
flatpak uninstall [APP_ID]

# Install native
sudo apt install [APP_NAME]
```

---

## Issue 3: Stutter Every 1-2 Seconds

### Symptoms
- Video stutters or freezes momentarily
- Regular interval (every 1-2 seconds)
- Network shows good speed
- Logs show no errors

### Causes
- Wrong encoder selected
- Frame pacing issues
- GPU power management
- Network buffer issues
- Client decoder struggling

### Solutions

#### A. Encoder Settings (Most Common Fix)

**NVIDIA:**
```ini
# In ~/.config/sunshine/sunshine.conf
encoder = nvenc
nv_preset = llhp
nv_rc = cbr
nv_coder = cabac
```

**AMD (VAAPI):**
```ini
encoder = vaapi
vaapi_preset = 0
vaapi_quality = 1
```

**AMD (AMF - if available):**
```ini
encoder = amf
amf_quality = 2
amf_usage = 2
```

**Intel:**
```ini
encoder = vaapi
vaapi_preset = 0
```

#### B. Frame Pacing (Client-Side)

In Moonlight settings:
- Set **"Video Frame Pacing"** to **"Prefer Smooth Video"**
- **DO NOT** use "Prefer Lowest Latency"

#### C. GPU Power Management

**NVIDIA:**
```bash
# Force maximum performance
nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1"

# Check if applied
nvidia-smi -q | grep -i "power"
```

**Intel/AMD:**
```bash
# CPU governor
sudo cpupower frequency-set -g performance
```

#### D. Disable Forward Error Correction (FEC)
```ini
# In sunshine.conf
fec_percentage = 0
```

#### E. Chunk Size
In Sunshine Web UI:
- **Configuration → Advanced → Chunk Size**
- Try **1** (reduces packet size, smoother delivery)

#### F. Bitrate Matching
```ini
# Match host and client bitrate
bitrate = 15000        # Sunshine
# Moonlight client: 15 Mbps
```

---

## Issue 4: Moonlight Reports "Low Connection" / Reduce Bitrate

### Symptoms
- Moonlight displays "Low connection to PC"
- Suggests reducing bitrate
- Network speed test shows adequate bandwidth

### Causes
- Bitrate mismatch between host and client
- WiFi interference
- Client decoder limitations
- Router QoS limiting traffic

### Solutions

#### Check Actual Bandwidth Usage
```bash
# Monitor network traffic
sudo iftop -i [INTERFACE]

# Check download speed to TV
# Look for actual Mbps being used during stream
```

#### TV-Specific Issues
If phone works but TV doesn't:
1. **TV's WiFi chip is slower/less capable**
2. **TV's processor can't decode fast enough**
3. **TV's Moonlight app outdated**

**Solutions:**
- Use Ethernet on TV
- Switch to 5GHz WiFi
- Set TV to 1080p (not 4K)
- Disable Motion Smoothing on TV
- Enable Game Mode on TV
- Update/reinstall Moonlight on TV

#### Force Bitrate
```ini
# In sunshine.conf
bitrate = 20000
max_bitrate = 20000
```

In Moonlight client:
- Set bitrate manually (not "Auto")
- Match host bitrate

---

## Issue 5: Encoder Not Available / Wrong Encoder

### Symptoms
- "Encoder not available" error
- High CPU usage
- Poor performance

### Solutions

#### Check Available Encoders
```bash
# NVIDIA
nvidia-smi

# VAAPI (Intel/AMD)
vainfo

# Check Sunshine logs
sudo journalctl -u sunshine | grep -i "encoder"
```

#### Force Specific Encoder
```bash
# In Web UI: Configuration → Advanced → Encoder
# Or in sunshine.conf:
encoder = nvenc    # NVIDIA
encoder = vaapi    # Intel/AMD
encoder = amf      # AMD
encoder = software # Fallback
```

#### Install Drivers
```bash
# NVIDIA
sudo ubuntu-drivers autoinstall
sudo reboot

# AMD VAAPI
sudo apt update
sudo apt install mesa-va-drivers libva2 libva-drm2
```

---

## Issue 6: Authentication Issues

### Symptoms
- Moonlight shows "Pairing Failed"
- Can't connect to Sunshine
- PIN not recognized

### Solutions

#### Find PIN in Sunshine
```bash
# In Web UI
# Configuration → Authentication → "New PIN"

# Or check logs
sudo journalctl -u sunshine | grep -i "pin"
```

#### Manual Pairing
1. In Sunshine Web UI: **Configuration → Authentication**
2. Click **"New PIN"**
3. Enter the PIN in Moonlight
4. Should connect

#### Firewall Issues
```bash
# Check firewall
sudo ufw status

# Allow required ports
sudo ufw allow 47984/tcp
sudo ufw allow 47989/tcp
sudo ufw allow 47990/tcp
sudo ufw allow 47998:48010/udp
```

---

## Issue 7: TV-Specific Issues

### Symptoms
- Phone works perfectly
- TV has stutter or low quality
- Same network, same settings

### Solutions

#### TV Network Optimization
1. **Use Ethernet** if available
2. **Switch to 5GHz WiFi** (not 2.4GHz)
3. **Move TV closer to router**
4. **Check TV's WiFi link speed** in network settings

#### TV Display Settings
1. Enable **Game Mode** (reduces input lag)
2. Disable **Motion Smoothing/MEMC**
3. Disable **Image Processing** features
4. Set resolution to **1080p** (even if 4K TV)

#### Moonlight on TV Settings
| Setting | Recommended |
|---------|-------------|
| Resolution | 1080p |
| FPS | 60 |
| Bitrate | 15 Mbps |
| Codec | H.264 (not HEVC) |
| Frame Pacing | Prefer Smooth Video |
| Audio | Stereo |

---

## Issue 8: Display Server Issues (Wayland)

### Symptoms
- Apps don't capture properly
- Black screen on client
- Only works with Xorg

### Solutions

#### Check Display Server
```bash
echo $XDG_SESSION_TYPE
```

#### Switch to Xorg
1. Log out
2. Click gear icon on login screen
3. Select **"Ubuntu on Xorg"**
4. Log in

#### Force X11 in Sunshine
```bash
# In sunshine.conf
video_source = x11
```

---

## Issue 9: App Not Found by Sunshine

### Symptoms
- App installed but not showing in Sunshine list
- Can't add app

### Solutions

#### Find Flatpak Executable
```bash
# List contents
flatpak run --command=ls [APP_ID] /app/bin/

# Get full path
flatpak info [APP_ID]
```

#### Add App in Sunshine
1. Sunshine Web UI → **Applications**
2. Click **"Add New"**
3. **Name:** App name
4. **Command:** Full command (e.g., `flatpak run net.pcsx2.PCSX2`)
5. **Working Directory:** `/home/[USER]`
6. **Output Name:** `PCSX2`
7. Click **"Save"**

---

## Issue 10: Persistent Stutter - Advanced Troubleshooting

### Diagnostic Steps

#### 1. Test with Simple App
```bash
# Add a simple app like Calculator
# Command: gnome-calculator
# If it stutters too → Sunshine/network issue
# If it's smooth → Specific app issue
```

#### 2. Monitor System Resources
```bash
# CPU usage
htop

# GPU usage (NVIDIA)
watch -n 0.5 nvidia-smi

# GPU usage (Intel/AMD)
watch -n 0.5 intel_gpu_top

# Network
sudo iftop -i [INTERFACE]
```

#### 3. Check Logs
```bash
# Sunshine logs
sudo journalctl -u sunshine -f

# Look for:
# - "dropped frames"
# - "packet loss"
# - "encoder overload"
# - "bitrate" changes
```

#### 4. Reset to Default
```bash
# Backup current config
mv ~/.config/sunshine ~/.config/sunshine.backup

# Restart Sunshine (generates default config)
sudo systemctl restart sunshine

# Reconfigure from scratch
```

### The "Nuclear" Options

#### Reinstall Sunshine
```bash
sudo dpkg -r sunshine
sudo apt autoremove
sudo dpkg -i sunshine-ubuntu-24.04-amd64.deb
sudo apt --fix-broken install
```

#### Try Different Sunshine Version
```bash
# Nightly build (may have fixes)
wget https://github.com/LizardByte/Sunshine/releases/download/nightly/sunshine-ubuntu-24.04-amd64.deb
sudo dpkg -i sunshine-ubuntu-24.04-amd64.deb
```

#### Use External Streaming Device
- Fire TV Stick 4K
- NVIDIA Shield TV
- Chromecast with Google TV

These have better decoding capabilities than built-in TV apps.

---

## Setting Reference Tables

### Sunshine Settings Reference

| Setting | Purpose | Recommended |
|---------|---------|-------------|
| `encoder` | GPU encoder | `nvenc`/`vaapi`/`amf` |
| `bitrate` | Target bitrate (kbps) | `15000-25000` |
| `fps` | Frames per second | `60` |
| `qp` | Quality (lower=better) | `23-28` |
| `fec_percentage` | Error correction | `0` (disable) |
| `nv_preset` | NVIDIA preset | `llhp` |
| `nv_rc` | NVIDIA rate control | `cbr` |
| `vaapi_preset` | VAAPI preset | `0` |
| `vaapi_quality` | VAAPI quality | `1-2` |

### Moonlight Settings Reference

| Setting | Purpose | Recommended |
|---------|---------|-------------|
| Resolution | Stream resolution | `1080p` |
| FPS | Frames per second | `60` |
| Bitrate | Target bitrate | `15-25 Mbps` |
| Codec | Video codec | `H.264` |
| Frame Pacing | Smoothness | `Prefer Smooth` |
| Audio | Audio channels | `Stereo` |

---

## Quick Command Reference

```bash
# Check Sunshine status
sudo systemctl status sunshine

# View Sunshine logs
sudo journalctl -u sunshine -f

# Restart Sunshine
sudo systemctl restart sunshine

# Check GPU
nvidia-smi                    # NVIDIA
vainfo                        # Intel/AMD VAAPI

# Check network
iwconfig                      # WiFi info
ping -c 100 [IP]              # Test latency

# Check dependencies
sudo apt --fix-broken install

# Find Flatpak executable
flatpak run --command=ls [APP_ID] /app/bin/

# Edit Sunshine config
nano ~/.config/sunshine/sunshine.conf
```

---

## Common Error Messages and Fixes

| Error | Fix |
|-------|-----|
| `dpkg: dependency problems` | `sudo apt --fix-broken install` |
| `encoder not available` | Install drivers, force correct encoder |
| `pairing failed` | Generate new PIN in Web UI |
| `low connection` | Check network, lower bitrate |
| `black screen` | Switch to Xorg, check display server |
| `stutter` | Change frame pacing, disable FEC |
| `app not found` | Use full path for Flatpak apps |

---

## Final Checklist

Before reporting issues, verify:

- [ ] Sunshine is running (`sudo systemctl status sunshine`)
- [ ] Correct encoder is selected
- [ ] Client and host bitrate match
- [ ] Frame pacing set to "Prefer Smooth"
- [ ] FEC is disabled
- [ ] Network is stable (ping < 30ms)
- [ ] TV has Game Mode enabled
- [ ] TV is on 5GHz WiFi or Ethernet
- [ ] Moonlight app is updated
- [ ] GPU drivers are up to date
```

---

## Summary

Both files are now ready:

1. **`sunshine-moonlight-setup-guide.md`** - Complete installation and setup guide
2. **`sunshine-moonlight-troubleshooting.md`** - Comprehensive troubleshooting reference

These cover everything from first-time installation to advanced troubleshooting, including all the solutions we discovered during our session. The guides are structured to be useful for both beginners and advanced users.

Would you like me to adjust anything or add additional sections to either file?