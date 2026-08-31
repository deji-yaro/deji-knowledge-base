## Purpose

Confirm that GPU passthrough is working correctly and drivers are functional.

## GPU Detection Tests

```bash
# 1. Check PCI devices in VM
lspci | grep VGA
# Should show: AMD Radeon RX 6750 XT (not virtual GPU)

# 2. Verify OpenGL renderer
glxinfo | grep "OpenGL renderer"
# Should show: AMD Radeon RX 6750 XT

# 3. Check Vulkan support
vulkaninfo | head -20
# Should list AMD GPU and Vulkan version

# 4. Test GPU compute
vainfo  # VA-API support
rocminfo  # ROCm compute (if installed)

```

**Performance Verification**

```bash
# Install and run basic benchmark
sudo apt install glmark2 -y
glmark2

# Install Steam for gaming tests
sudo apt install steam -y

# Check GPU memory usage
watch -n 1 'cat /sys/class/drm/card0/device/mem_info_vram_used'

```

**Host-Side Verification**

```bash
# On Proxmox host, verify GPU is bound to VM
lspci -s 03:00.0 -k
# Should show: Kernel driver in use: vfio-pci

# Check VM is using the device
lsof /dev/vfio/*

```