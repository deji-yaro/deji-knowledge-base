#01-guides
```bash
# Edit the GRUB bootloader configuration file.
nano /etc/default/grub

# MODIFY the following line:
# For an INTEL CPU:
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
# For an AMD CPU:
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"
```

- `**intel_iommu=on**`** / **`**amd_iommu=on**`**:** Enables the IOMMU.
- `**iommu=pt**`**:** Stands for "Passthrough". This tells the kernel to only enable IOMMU translation for devices used in passthrough, reducing overhead for devices not being passed through. It's a performance optimization.
- `**quiet**`**:** Hides most boot messages, keeping the boot process clean.

```bash
# Apply the GRUB configuration change.update-grub
```