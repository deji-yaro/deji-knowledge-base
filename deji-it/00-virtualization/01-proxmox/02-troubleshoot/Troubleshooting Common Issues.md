## Purpose

Resolve typical problems encountered during GPU passthrough setup.

## Issue: Black Screen After Driver Install

**Solution:**

```bash
bash# 1. Temporarily disable GPU passthrough# Edit VM config: vga: virtio (instead of none)# Remove hostpci lines# Install drivers with virtual display# Re-enable passthrough after successful install# 2. Add VM arguments for AMD compatibility
args: -cpu host,hidden=1
```

## Issue: NoVNC Console Won't Connect

**Solutions:**

```bash
bash# 1. Restart Proxmox web service
systemctl restart pveproxy

# 2. Clear browser cache or try different browser# 3. Temporarily enable virtual display# VM config: vga: virtio# 4. Regenerate certificates
pvecm updatecerts --force
systemctl restart pveproxy
```

## Issue: VM Won't Shutdown (Timeout Error)

**Solution:**

```bash
# Force stop VM
qm stop 100

# If locked:
qm unlock 100
qm stop 100

# Install guest agent to prevent future issues
sudo apt install qemu-guest-agent -y
# Enable in VM Options: QEMU Guest Agent = Yes
```

## Issue: USB Devices Not Detected

**Solutions:**

```bash
# 1. Reset USB subsystem on host
echo 1 > /sys/bus/pci/rescan

# 2. Check device IDs
lsusb
qm set 100 -usb0 host=XXXX:YYYY  # Use actual IDs# 3. Try different USB ports (2.0 vs 3.0)
```