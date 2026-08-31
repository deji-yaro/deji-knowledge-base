#01-guides
## Purpose

Configure PCI passthrough for GPU and audio components to VM.

## Add GPU via Web Interface

1. **Stop the VM** (important!)
2. **Hardware Tab > Add > PCI Device**
3. **Select GPU (e.g., 0000:03:00.0)**
4. **Check these options:**
    - ✅ All Functions
    - ✅ PCI-Express
    - ✅ ROM-Bar
    - ✅ Primary GPU
5. **Add GPU Audio separately (0000:03:00.1)**
    - Same options except Primary GPU

## Add GPU via Command Line

```bash
# Add GPU to VM
qm set 100 -hostpci0 0000:03:00.0,pcie=1,rombar=1,x-vga=0

# Add GPU audio
qm set 100 -hostpci1 0000:03:00.1,pcie=1

# Set display to none
qm set 100 -vga none
```

## Troubleshooting GPU Passthrough

```bash
# If VM shows black screen, add these args to VM config:
args: -cpu host,hidden=1

# Check VM uses vfio-pci driver on host:
lspci -s 03:00.0 -k  # Should show vfio-pci in use
```