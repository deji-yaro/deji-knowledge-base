#01-guides
## Purpose

Enable keyboard, mouse, and other USB devices in the VM for native experience.

## Method 1: Individual Device Passthrough (Recommended)

```bash
# List USB devices on host
lsusb

# Add specific devices to VM
qm set 100 -usb0 host=046a:0023  # Cherry keyboard
qm set 100 -usb1 host=046d:c09d  # Logitech mouse
```

## Method 2: USB Controller Passthrough (Maximum Flexibility)

```bash
# Find USB controller
lspci -nn | grep USB

# Add entire USB controller to VM
qm set 100 -hostpci2 0000:00:14.0,pcie=1
```

## Web Interface Method

1. **VM Hardware > Add > USB Device**
2. **Choose method:**
    - **Use USB Port:** For specific port assignment
    - **Use USB Vendor/Device ID:** For device flexibility
3. **Select your devices from dropdown**

## Troubleshooting USB Issues

`bash``*# If devices not detected, reset USB subsystem:*``
modprobe -r xhci_hcd
modprobe xhci_hcd

``*# Check if devices are visible in VM:*``
lsusb  ``*# Run inside VM*`