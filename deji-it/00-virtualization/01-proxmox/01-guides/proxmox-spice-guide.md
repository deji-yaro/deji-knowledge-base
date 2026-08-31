# SPICE Configuration Guide for Proxmox — Windows 10 VM

## What is SPICE?

SPICE (Simple Protocol for Independent Computing Environments) is a remote display protocol designed specifically for virtualization. Unlike RDP which was designed for Windows remote administration, SPICE was built from the ground up to work with QEMU/KVM virtual machines and is the native remote display protocol for Proxmox.

It supports:
- Dynamic resolution resizing
- Clipboard sharing between host and guest
- USB redirection
- Audio passthrough
- Optimized screen update compression

---

## How SPICE Works in Proxmox

The connection flow is:

```
Client (remote-viewer) → Proxmox SPICE Proxy (port 3128) → KVM/QEMU → Windows VM
```

Proxmox manages SPICE via time-limited tickets. Every time you request a SPICE connection from the web UI, Proxmox generates a `.vv` file containing a one-time password that expires in approximately 60 seconds. This is by design for security — the ticket is only valid for the initial handshake. Once connected, the session stays alive indefinitely until you close it.

---

## Prerequisites

### On the Proxmox Node
- VM display set to **SPICE (QXL)**
- Machine type: **q35**
- CPU type: **host**

### Inside Windows 10 (Guest)
Install **virtio-win-guest-tools.exe** from the VirtIO Windows ISO:
```
https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/
```

This installs:
- Red Hat QXL display driver
- SPICE vdagent (clipboard sync, auto-resize, mouse handling)
- VirtIO storage, network, and SCSI drivers

### On the Client Machine (Ubuntu)
```bash
sudo apt install remote-viewer
```

---

## Proxmox VM Recommended Configuration

```
Display:          SPICE (QXL), Memory: 128MB
Machine:          q35
CPU:              host
Network:          VirtIO
Disk controller:  VirtIO SCSI
Disk cache:       Write back
Async IO:         io_uring
SPICE enhancements: videostreaming=filter
```

Apply SPICE enhancements via CLI:
```bash
qm set <vmid> -spice_enhancements foldersharing=0,videostreaming=filter
```

---

## Why Only 128MB Video Memory Works

This is one of the most commonly encountered issues with QXL on Windows guests. The QXL driver has a hard practical limit around 128MB due to several compounding factors:

### 1. QXL is a Legacy Driver
QXL was designed in the early KVM era and uses the **WDDM 1.x** driver model. This older model has limitations in how it maps and manages large framebuffer regions. Above 128MB the driver can fail to initialize the display pipeline entirely, resulting in a black screen.

### 2. PCI BAR Mapping Conflict
QEMU maps QXL video RAM into the guest's PCI Base Address Register (BAR). On a q35 machine with Windows, setting video memory above 128MB can cause this mapping to conflict with other PCI memory regions. Windows is stricter than Linux about PCI memory layout, making it more likely to hit this conflict.

### 3. WDDM 1.x Framebuffer Ceiling
The WDDM 1.x model used by the QXL driver has a practical ceiling on how much video RAM it can coherently address. Beyond 128MB the driver loses stability — not because the hardware can't handle it, but because the driver model wasn't designed for it.

### 4. VirtIO-GPU Does Not Help
VirtIO-GPU uses WDDM 2.x and supports higher memory values, but it is designed for local or passthrough use — not remote streaming. When used with SPICE it performs significantly worse than QXL because it lacks QXL's built-in delta compression and screen update optimization that SPICE relies on. QXL + SPICE is a co-designed stack. VirtIO-GPU + SPICE is not.

**The safe and recommended value is 128MB.** It provides enough framebuffer for resolutions up to 2560x1440 (requiring ~28MB) with plenty of headroom, while staying within the stable range of the QXL WDDM 1.x driver.

---

## Connecting from Ubuntu

### The .vv File Problem
The `.vv` file Proxmox generates expires in ~60 seconds and is deleted by remote-viewer after use (`delete-this-file=1`). Additionally, the proxy line in the file points to whichever Proxmox node is configured as the cluster proxy, which may not be directly reachable.

### Automated Connection Script
Save as `~/spice.sh` to bypass the browser entirely:

```bash
#!/bin/bash

PROXMOX_HOST="<proxmox-node-ip>"
PROXMOX_USER="root@pam"
PROXMOX_PASS="<your-password>"
VMID="<vm-id>"
NODE="<node-name>"

# Get auth ticket
RESPONSE=$(curl -sk -d "username=${PROXMOX_USER}&password=${PROXMOX_PASS}" \
  https://${PROXMOX_HOST}:8006/api2/json/access/ticket)

TICKET=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['ticket'])")
CSRF=$(echo $RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['CSRFPreventionToken'])")

# Get fresh SPICE config
curl -sk \
  -H "Cookie: PVEAuthCookie=${TICKET}" \
  -H "CSRFPreventionToken: ${CSRF}" \
  -X POST \
  --data "proxy=http://${PROXMOX_HOST}:3128" \
  https://${PROXMOX_HOST}:8006/api2/spiceconfig/nodes/${NODE}/qemu/${VMID}/spiceproxy \
  > /tmp/spice.vv

remote-viewer /tmp/spice.vv
```

```bash
chmod +x ~/spice.sh
```

Run `~/spice.sh` whenever you need to connect. Once connected, just minimize — the session stays alive.

### inotifywait Alternative (if script doesn't work)
If you prefer downloading from the browser, use a folder watcher to catch and fix the file before it expires:

```bash
sudo apt install inotify-tools

while inotifywait -e create ~/Downloads; do
  if [ -f ~/Downloads/pve-spice.vv ]; then
    cp ~/Downloads/pve-spice.vv /tmp/spice.vv
    sed -i 's|delete-this-file=1|delete-this-file=0|' /tmp/spice.vv
    sed -i 's|proxy=http://.*:3128|proxy=http://<proxmox-node-ip>:3128|' /tmp/spice.vv
    remote-viewer /tmp/spice.vv
  fi
done
```

---

## What Affects Connection Quality

### Things That Matter (in order of impact)

| Factor | Impact | Fix |
|---|---|---|
| Resolution mismatch | Very High | Set VM resolution to match client native resolution |
| Wrong display driver | Very High | Must use QXL, not Standard VGA |
| SPICE agent not running | High | Check services.msc → SPICE Agent → Running |
| Network NIC type | High | Use VirtIO NIC, not e1000e |
| Disk controller type | Medium | Use VirtIO SCSI, not SATA |
| Video memory | Medium | 128MB sweet spot for QXL |
| SPICE enhancements | Medium | Enable videostreaming=filter |
| CPU type | Low-Medium | Use host passthrough |
| Machine type | Low | q35 preferred over i440fx |

### Things That Do NOT Matter
- Network bandwidth — even 100Mbps is more than enough for SPICE
- RAM amount — SPICE doesn't care how much RAM the VM has
- Disk speed — affects app launch times, not display smoothness

---

## Why SPICE Still Feels Slightly Worse Than Native Despite Perfect Configuration

This is the honest answer that most guides don't give you.

### 1. It Is a Remote Protocol
Every frame has to be: captured from the virtual framebuffer → encoded → sent over the network → decoded → rendered on your display. Even on a LAN with sub-1ms latency, this pipeline adds inherent delay. No amount of tuning eliminates this — it can only be minimized.

### 2. Mouse Mode Limitations
SPICE in remote-viewer v11 has limited mouse mode control. The absolute mouse mode (default) calculates cursor position client-side and syncs it to the server, which introduces a small but perceptible lag on fast mouse movements. Older versions of remote-viewer had a grab/relative mode option that felt significantly better — this was removed in v11.

The USB tablet device (`qm set <vmid> -tablet 1`) helps but doesn't fully solve it — it makes absolute positioning more accurate but doesn't eliminate the protocol round-trip.

### 3. QXL is Not GPU Accelerated
QXL is a purely software display adapter. There is no GPU acceleration inside the VM. Every window animation, transparency effect, and cursor movement is rendered by the CPU, compressed by the QXL driver, and sent via SPICE. Windows 10 with Aero effects was designed to run on GPU-accelerated hardware — on a software display adapter it will always feel slightly off regardless of how fast the CPU is.

### 4. Frame Pacing
SPICE doesn't guarantee consistent frame delivery timing. Frames are sent as they are generated, which means fast motion (window dragging, scrolling) can feel stuttery even when average throughput is fine. RDP has the same issue.

### 5. The Comparison Point is Unfair
Native feel means zero encoding, zero network, zero decoding — the GPU writes directly to the display. Any remote protocol, no matter how well optimized, cannot match this. SPICE at its best is excellent for remote administration, office work, and general use. It is not designed to replace a local workstation experience.

---

## The Only Real Fix for Native Feel

**GPU Passthrough** — pass a physical GPU from the Proxmox host directly into the VM. The VM then drives a real GPU with real drivers. SPICE or RDP is no longer used — instead you connect a physical monitor directly to the GPU output, or use a capture card. This gives true native performance because there is no encoding/decoding pipeline.

Requirements:
- A GPU installed in the Proxmox server
- IOMMU enabled in BIOS (VT-d on Intel)
- Compatible IOMMU grouping
- `vfio` kernel modules configured on the host

---

## Quick Verification Checklist

```
[ ] Display set to SPICE (QXL) in Proxmox Hardware
[ ] Video memory set to 128MB
[ ] Machine type: q35
[ ] CPU type: host
[ ] Network adapter: VirtIO
[ ] Disk controller: VirtIO SCSI
[ ] virtio-win-guest-tools.exe installed in Windows
[ ] Device Manager shows: Red Hat QXL controller (no warning icon)
[ ] services.msc shows: SPICE Agent → Running, Automatic
[ ] VM resolution matches client native resolution
[ ] SPICE enhancements videostreaming=filter applied
[ ] Connecting via ~/spice.sh (not manual .vv download)
[ ] remote-viewer window kept open and minimized when not in use
```
