This document covers the architecture, configuration, and troubleshooting of multi-booting multiple Linux distributions on a single UEFI system. 

## 1. Core Architecture Concepts

Before touching partitions, understand how UEFI boot actually works. There are two distinct layers:

1. **The EFI System Partition (ESP):** A FAT32 partition (usually 500MB–1GB) mounted at `/boot/efi` or `/boot`. The motherboard's firmware natively reads FAT32. Each distro creates its own directory here (e.g., `/EFI/ubuntu/`, `/EFI/fedora/`).
2. **The NVRAM Boot Order:** The motherboard's non-volatile RAM stores a prioritized list of `.efi` executables to run. 

**The Golden Rule of Multi-Booting:** 
Never let two distros try to manage the *same* GRUB configuration. Either use **Independent Bootloaders** (selecting the OS via the motherboard's F12/F11 boot menu) or designate one **Master GRUB** to chainload the others.

---

## 2. Method A: Independent Bootloaders (Recommended)

This is the most resilient setup. Each distro installs its own bootloader to the shared ESP. You select the OS using your motherboard's hardware boot menu (e.g., F12), or by reordering the NVRAM priority.

### What to check:
Verify the ESP contains the correct files and NVRAM points to them.

```bash
# 1. Check ESP contents
ls /boot/efi/EFI/

# 2. Check NVRAM boot order
sudo efibootmgr -v
```

### How to fix/add an entry manually:
If an installer fails to write to NVRAM (like your Nobara install), add it manually.

```bash
# Syntax: efibootmgr --create --disk <drive> --part <esp_partition_num> --label "<Name>" --loader <path_inside_ESP>
sudo efibootmgr --create --disk /dev/nvme0n1 --part 2 --label "Nobara" --loader /EFI/fedora/shimx64.efi
```
*Note: Always use `shimx64.efi` instead of `grubx64.efi` if Secure Boot is enabled, as `shim` is signed by Microsoft and will validate GRUB.*

---

## 3. Method B: Master GRUB & Chainloading (os-prober)

If you want a single GRUB menu to boot all distros, one distro's GRUB must detect the others. This relies on a script called `os-prober`.

### The File to Edit: `/etc/default/grub`
By default, modern distros (Ubuntu 22.04+, Fedora) disable `os-prober` for security (mitigating BootHole-style attacks where a malicious USB injects a fake OS entry).

**Steps to enable:**
1. Open the config:
   ```bash
   sudo nano /etc/default/grub
   ```
2. Add or uncomment this exact line at the bottom:
   ```text
   GRUB_DISABLE_OS_PROBER=false
   ```
3. Save and exit.

### The Command to Apply:
You must regenerate the actual GRUB config file (`/boot/grub/grub.cfg`). The command depends on the distro whose GRUB is acting as the master:

* **Debian/Ubuntu/Mint/Pop:**
  ```bash
  sudo update-grub
  ```
* **Fedora/Nobara/RHEL:**
  ```bash
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg
  # Note: On some Fedora UEFI setups, the path is /boot/efi/EFI/fedora/grub.cfg
  ```

### Limitations of os-prober (Crucial):
`os-prober` is dumb. It looks for standard `/boot/vmlinuz` and `/boot/initrd` files on standard ext4 partitions. 
* **It will FAIL** if the target distro uses **Btrfs** (it doesn't understand subvolumes).
* **It will FAIL** if the target distro uses **LUKS encryption** (it can't read through the encryption header without a passphrase).
* **It will FAIL** if the target distro uses **LVM**.

If your secondary distro uses any of these, you *must* use Method A (Independent Bootloaders).

---

## 4. Troubleshooting Matrix

When a distro disappears, isolate the failure layer using this matrix.

### Symptom 1: OS is missing from the Motherboard Boot Menu (F12)
**Diagnosis:** NVRAM issue or missing ESP files.
1. Boot into a working OS or Live USB.
2. Check if the files exist: `ls /boot/efi/EFI/<distro_name>/`.
3. If files exist, NVRAM is missing the entry. Use `sudo efibootmgr --create ...` (see Method A).
4. If files are missing, the installer failed. Chroot into the distro and reinstall GRUB (see Section 5).

### Symptom 2: OS is in BIOS menu, but boots into the wrong OS / GRUB menu is missing it
**Diagnosis:** GRUB configuration issue.
1. If using Method A: You are booting the wrong GRUB. Use F12 to select the correct one.
2. If using Method B: `os-prober` failed. Check the output of `sudo update-grub` or `grub2-mkconfig`. If it doesn't say "Found [Distro]", check the limitations in Section 3.

### Symptom 3: Black screen, "Security Violation", or "Invalid Signature"
**Diagnosis:** Secure Boot mismatch.
1. The UEFI is trying to load an unsigned `grubx64.efi`.
2. Fix: Change the NVRAM entry to point to `shimx64.efi` instead.
3. Alternative: Disable Secure Boot in the BIOS.
4. Advanced: If you compiled a custom kernel, you need to sign it and enroll the key using `mokutil` and `kmodsign`.

---

## 5. Recovery: The Chroot Procedure

If a distro's bootloader is completely nuked, you must chroot into it from a Live USB to reinstall it.

**1. Boot the Live USB and identify partitions:**
```bash
lsblk
```

**2. Mount the root filesystem:**
*For standard ext4:*
```bash
sudo mount /dev/nvme0n1pX /mnt
```
*For Btrfs (assuming default `@` subvolume for root):*
```bash
sudo mount -o subvol=@ /dev/nvme0n1pX /mnt
```

**3. Mount the virtual filesystems and ESP:**
```bash
sudo mount /dev/nvme0n1pY /mnt/boot/efi   # Replace pY with your ESP partition
for i in dev dev/pts proc sys run; do sudo mount -B /$i /mnt/$i; done
```

**4. Chroot and reinstall:**
```bash
sudo chroot /mnt

# For Ubuntu/Debian:
grub-install /dev/nvme0n1
update-grub

# For Fedora/Nobara:
grub2-install /dev/nvme0n1
grub2-mkconfig -o /boot/grub2/grub.cfg

exit
sudo reboot
```

---

## 6. Best Practices for IT Admins

1. **Keep a 1GB ESP:** 100MB is the legacy default. It's too small. When you have 3-4 distros, kernel updates, and fallback initrds, a 100MB ESP will fill up and break kernel updates.
2. **Don't format the ESP:** When installing a new distro, choose "Manual Partitioning". Assign the existing ESP to `/boot/efi`, but **ensure the "Format" checkbox is UNCHECKED**. If you format it, you delete the bootloaders for your other OSes.
3. **Separate `/boot` for LUKS:** If you encrypt your root drive with LUKS, the `/boot` directory (which holds the kernel and initramfs) *must* reside on an unencrypted partition, or the system cannot boot. The installer usually handles this, but verify it in manual partitioning.