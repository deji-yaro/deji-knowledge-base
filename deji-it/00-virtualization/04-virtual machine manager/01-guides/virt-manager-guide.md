# Virtual Machine Manager (virt-manager) — Complete Guide

> **Scope:** This guide targets intermediate Linux users across Ubuntu/Debian, Fedora/RHEL/CentOS, and Arch Linux. It covers installation, GUI usage, SPICE integration, disk/file management, and CLI equivalents for every major operation.

---

## Table of Contents

1. [What Is virt-manager?](#1-what-is-virt-manager)
2. [Prerequisites — Checking KVM Support](#2-prerequisites--checking-kvm-support)
3. [Installation](#3-installation)
4. [Starting & Enabling the Libvirt Daemon](#4-starting--enabling-the-libvirt-daemon)
5. [Adding Your User to the libvirt Group](#5-adding-your-user-to-the-libvirt-group)
6. [Launching the GUI & Creating Your First VM](#6-launching-the-gui--creating-your-first-vm)
7. [Using SPICE for Better Performance](#7-using-spice-for-better-performance)
8. [Navigating and Editing Files & Disks](#8-navigating-and-editing-files--disks)
9. [CLI Management with virsh](#9-cli-management-with-virsh)
10. [Useful Tips & Troubleshooting](#10-useful-tips--troubleshooting)

---

## 1. What Is virt-manager?

**Virtual Machine Manager** (`virt-manager`) is a desktop GUI front-end for managing virtual machines through `libvirt`. Under the hood it uses **KVM** (Kernel-based Virtual Machine) and **QEMU** to provide near-native performance. Key components:

| Component | Role |
|-----------|------|
| `kvm` | Kernel module — hardware-accelerated virtualisation |
| `qemu` | Emulator/hypervisor backend |
| `libvirt` | Unified API and daemon (`libvirtd` / `virtqemud`) |
| `virt-manager` | GUI front-end |
| `virsh` | CLI front-end for libvirt |
| `spice` | Enhanced display/input protocol for VMs |

---

## 2. Prerequisites — Checking KVM Support

Before installing anything, confirm your CPU supports hardware virtualisation:

```bash
# Check for VMX (Intel) or SVM (AMD) flags
grep -Ec '(vmx|svm)' /proc/cpuinfo
```

A result greater than `0` means KVM is supported. You can also use:

```bash
kvm-ok          # Ubuntu (apt install cpu-checker)
# or
LC_ALL=C lscpu | grep Virtualization
```

Make sure virtualisation is **enabled in your UEFI/BIOS** (usually listed as "Intel VT-x", "AMD-V", or "SVM").

---

## 3. Installation

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    ovmf \
    spice-vdagent \
    virtinst
```

### Fedora / RHEL 9+ / CentOS Stream

```bash
sudo dnf install -y \
    @virtualization \
    virt-manager \
    spice-vdagent \
    edk2-ovmf
```

> `@virtualization` is a DNF group that pulls in qemu-kvm, libvirt, and related tools automatically.

### Arch Linux

```bash
sudo pacman -S --needed \
    qemu-full \
    libvirt \
    virt-manager \
    dnsmasq \
    bridge-utils \
    ovmf \
    spice-vdagent \
    virt-viewer
```

---

## 4. Starting & Enabling the Libvirt Daemon

### Modern distros (Fedora 35+, Ubuntu 22.04+, Arch)

These use **modular libvirt daemons**:

```bash
sudo systemctl enable --now virtqemud.socket
sudo systemctl enable --now virtnwfilterd.socket
sudo systemctl enable --now virtnetworkd.socket
sudo systemctl enable --now virtstoraged.socket
```

### Older / traditional setup (single daemon)

```bash
sudo systemctl enable --now libvirtd
```

Verify it is running:

```bash
sudo systemctl status libvirtd   # or virtqemud
virsh -c qemu:///system list --all
```

### Enable the default NAT network

```bash
sudo virsh net-start default
sudo virsh net-autostart default
```

---

## 5. Adding Your User to the libvirt Group

Without this step you would need `sudo` for every `virsh` or `virt-manager` command.

```bash
sudo usermod -aG libvirt,kvm $USER
```

Then **log out and back in** (or `newgrp libvirt` for the current session) for the group membership to take effect.

Verify:

```bash
groups $USER
# should include: libvirt kvm
```

---

## 6. Launching the GUI & Creating Your First VM

### Launch virt-manager

```bash
virt-manager
```

Or find it in your application menu under **"Virtual Machine Manager"**.

### Connect to the hypervisor

On first launch, virt-manager connects to `qemu:///system` automatically. You should see the main window with a connection listed. If not, go to **File → Add Connection** and select `QEMU/KVM`.

### Creating Your First VM — Step by Step

1. Click **"Create a new virtual machine"** (the monitor icon with a `+`).

2. **Step 1 — Installation source**
   - Choose `Local install media (ISO image or CDROM)`.
   - Browse to your `.iso` file.
   - virt-manager will attempt to auto-detect the OS; confirm or set it manually.

3. **Step 2 — Memory and CPU**
   - RAM: start with at least `2048 MiB` for a modern OS guest.
   - CPUs: `2` vCPUs is a safe default; never exceed your physical core count.

4. **Step 3 — Storage**
   - Create a new disk image (recommended: **qcow2** format for snapshots and thin provisioning).
   - Default location: `/var/lib/libvirt/images/`
   - Size: 20–40 GiB for a typical desktop guest.

5. **Step 4 — Network**
   - Default `NAT` (Virtual Network 'default') works out of the box and gives internet access.
   - For a bridged network (same subnet as host), you'll need to configure a bridge interface first.

6. **Step 5 — Summary**
   - Tick **"Customize configuration before install"** to review hardware before booting.
   - Click **Finish** — the VM console opens and installation begins.

### Key GUI Areas

| Area | What It Does |
|------|-------------|
| Main window | Lists all VMs and their state |
| VM console | SPICE/VNC display of the running guest |
| "i" (Details) button | Shows hardware config — add/remove devices |
| Snapshots tab | Create, restore, delete snapshots |
| Clone | Duplicate an existing VM |

---

## 7. Using SPICE for Better Performance

SPICE (Simple Protocol for Independent Computing Environments) gives you clipboard sharing, dynamic resolution, USB redirection, and better graphics vs. plain VNC.

### Ensure SPICE is selected (GUI)

1. Open VM details (**Edit → Virtual Machine Details** or the `i` button).
2. Go to **Display Spice** — confirm type is `Spice Server`.
3. Go to **Video** — set model to `QXL` (best with SPICE) or `Virtio` (best overall performance).
4. Go to **Sound** — set model to `ich9` or `ac97` for audio passthrough.

### Install the SPICE guest agent inside the VM

**Linux guest:**
```bash
# Debian/Ubuntu guest
sudo apt install spice-vdagent

# Fedora/RHEL guest
sudo dnf install spice-vdagent

# Arch guest
sudo pacman -S spice-vdagent
```

Then enable it:
```bash
sudo systemctl enable --now spice-vdagentd
```

**Windows guest:** Install the [VirtIO Windows drivers ISO](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso) — it includes the SPICE agent and VirtIO drivers.

### SPICE features once the agent is running

| Feature | Requirement |
|---------|------------|
| Clipboard sharing | spice-vdagent in guest |
| Auto-resize resolution | spice-vdagent + QXL/Virtio video |
| Folder sharing | Add `Filesystem` device in VM details |
| USB redirection | Add `USB Redirector` in VM details |

### Connecting via virt-viewer (standalone SPICE client)

```bash
virt-viewer --connect qemu:///system <vm-name>
# or by domain ID
virt-viewer --connect qemu:///system 1
```

---

## 8. Navigating and Editing Files & Disks

### Default storage locations

| Path | Contents |
|------|----------|
| `/var/lib/libvirt/images/` | Default disk images (`.qcow2`, `.img`) |
| `/etc/libvirt/qemu/` | XML configuration files for each VM |
| `/var/log/libvirt/qemu/` | Per-VM log files |
| `/var/lib/libvirt/network/` | Network definitions |

### Disk image formats

| Format | Use case |
|--------|----------|
| `qcow2` | Default — supports snapshots, compression, thin provisioning |
| `raw` | Fastest I/O, no features |
| `vmdk` | VMware compatibility |

### Resizing a disk image

```bash
# 1. Shut down the VM first!
# 2. Resize the image file
sudo qemu-img resize /var/lib/libvirt/images/myvm.qcow2 +20G

# 3. Boot the VM and resize the partition/filesystem inside the guest
# (use gparted, growpart, or resize2fs/xfs_growfs)
```

### Converting disk formats

```bash
# qcow2 → raw
qemu-img convert -f qcow2 -O raw input.qcow2 output.raw

# raw → qcow2
qemu-img convert -f raw -O qcow2 input.raw output.qcow2

# Check image info
qemu-img info /var/lib/libvirt/images/myvm.qcow2
```

### Adding a new disk to an existing VM (GUI)

1. Open **VM Details → Add Hardware → Storage**.
2. Choose **Create a disk image** or point to an existing file.
3. Set bus type: **VirtIO** (best performance) or SATA/IDE (wider compatibility).
4. Click **Finish** — no reboot needed if the guest supports hotplug.

### Editing VM XML directly

```bash
sudo virsh edit <vm-name>
```

This opens the VM's XML in your `$EDITOR`. Changes take effect on the next boot. Important XML sections:

```xml
<!-- CPU & Memory -->
<memory unit='KiB'>4194304</memory>
<vcpu placement='static'>4</vcpu>

<!-- Disk -->
<disk type='file' device='disk'>
  <driver name='qemu' type='qcow2' cache='writeback'/>
  <source file='/var/lib/libvirt/images/myvm.qcow2'/>
  <target dev='vda' bus='virtio'/>
</disk>

<!-- Network interface -->
<interface type='network'>
  <source network='default'/>
  <model type='virtio'/>
</interface>
```

### Mounting a guest disk image on the host (offline)

```bash
# Install guestfs tools
sudo apt install libguestfs-tools   # Debian/Ubuntu
sudo dnf install libguestfs-tools   # Fedora

# List partitions inside the image
sudo virt-filesystems -a /var/lib/libvirt/images/myvm.qcow2 --all --long

# Mount read-only
sudo guestmount -a /var/lib/libvirt/images/myvm.qcow2 -i --ro /mnt/guest

# Unmount when done
sudo guestunmount /mnt/guest
```

### Snapshots

**GUI:** Open VM Details → **Snapshots** tab → click `+` to create.

**CLI:**
```bash
virsh snapshot-create-as <vm-name> snap1 "Before update" --disk-only
virsh snapshot-list <vm-name>
virsh snapshot-revert <vm-name> snap1
virsh snapshot-delete <vm-name> snap1
```

---

## 9. CLI Management with virsh

`virsh` is the primary CLI tool for managing all aspects of your VMs. Connect to the system hypervisor by default with `virsh -c qemu:///system` or set the environment variable:

```bash
export LIBVIRT_DEFAULT_URI="qemu:///system"
```

### VM Lifecycle

```bash
virsh list --all                   # List all VMs (running and stopped)
virsh start <vm-name>              # Start a VM
virsh shutdown <vm-name>           # Graceful shutdown (requires guest agent)
virsh destroy <vm-name>            # Force power off
virsh reboot <vm-name>             # Reboot
virsh suspend <vm-name>            # Pause (saves CPU state in RAM)
virsh resume <vm-name>             # Resume from pause
virsh save <vm-name> state.bin     # Save to disk (hibernate)
virsh restore state.bin            # Restore from disk
virsh undefine <vm-name>           # Delete VM definition (keeps disk!)
virsh undefine <vm-name> --remove-all-storage  # Delete VM + disks
```

### Creating a VM from CLI (virt-install)

```bash
virt-install \
  --name ubuntu24 \
  --ram 4096 \
  --vcpus 2 \
  --os-variant ubuntu24.04 \
  --disk path=/var/lib/libvirt/images/ubuntu24.qcow2,size=40,format=qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice \
  --video qxl \
  --cdrom /path/to/ubuntu-24.04-desktop-amd64.iso \
  --boot cdrom,hd \
  --noautoconsole
```

List valid OS variants:
```bash
osinfo-query os | grep ubuntu
```

### Cloning a VM

```bash
virt-clone \
  --original <source-vm> \
  --name <new-vm> \
  --auto-clone
```

### Resource Management

```bash
# Change RAM (requires VM to be shut off for most changes)
virsh setmaxmem <vm-name> 8G --config
virsh setmem <vm-name> 8G --config

# Change vCPU count
virsh setvcpus <vm-name> 4 --config --maximum
virsh setvcpus <vm-name> 4 --config

# View current config
virsh dominfo <vm-name>
virsh domstats <vm-name>
```

### Disk Management via CLI

```bash
# List disks attached to a VM
virsh domblklist <vm-name>

# Attach an existing disk image
virsh attach-disk <vm-name> \
  /var/lib/libvirt/images/extra.qcow2 \
  vdb \
  --driver qemu \
  --subdriver qcow2 \
  --persistent

# Detach a disk
virsh detach-disk <vm-name> vdb --persistent
```

### Network Management

```bash
virsh net-list --all               # List all virtual networks
virsh net-start default            # Start default NAT network
virsh net-autostart default        # Enable at boot
virsh net-info default             # Show network details
virsh net-dumpxml default          # Print network XML config
virsh net-edit default             # Edit network config

# List network interfaces of a VM
virsh domiflist <vm-name>

# Attach a NIC
virsh attach-interface <vm-name> network default --model virtio --persistent

# Detach a NIC (use MAC from domiflist)
virsh detach-interface <vm-name> network --mac 52:54:00:xx:xx:xx --persistent
```

### Console Access (no GUI)

```bash
# Serial console (guest must have serial console configured)
virsh console <vm-name>
# Press Ctrl+] to exit

# SPICE/VNC via virt-viewer
virt-viewer <vm-name>
```

### Snapshots via CLI

```bash
virsh snapshot-create-as <vm> snap1 "Clean state"
virsh snapshot-list <vm>
virsh snapshot-info <vm> snap1
virsh snapshot-revert <vm> snap1
virsh snapshot-delete <vm> snap1
```

### Storage Pool Management

```bash
virsh pool-list --all              # List storage pools
virsh pool-info default            # Info about default pool
virsh vol-list default             # List volumes in pool
virsh vol-info myvm.qcow2 default  # Info about a volume
virsh vol-delete myvm.qcow2 default  # Delete a volume
```

---

## 10. Useful Tips & Troubleshooting

### Enable nested virtualisation (run VMs inside VMs)

```bash
# Intel
echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm-intel.conf

# AMD
echo "options kvm-amd nested=1" | sudo tee /etc/modprobe.d/kvm-amd.conf

sudo modprobe -r kvm_intel && sudo modprobe kvm_intel   # or kvm_amd
```

### Improve disk performance

In VM XML, set the cache mode on your disk driver:

```xml
<driver name='qemu' type='qcow2' cache='writeback' io='threads'/>
```

For databases or high-I/O workloads, use `cache='none'` with a raw disk.

### Enable VirtIO for best network and disk performance

When creating or editing a VM, always choose:
- **Disk bus:** VirtIO
- **Network model:** VirtIO (virtio)

### libvirt permission errors

If you get `authentication failed` or `access denied`:

```bash
# Check group membership
groups
# Add yourself if missing
sudo usermod -aG libvirt,kvm $USER
# Then log out and back in
```

### VM won't start — check logs

```bash
sudo journalctl -u libvirtd -n 50
sudo cat /var/log/libvirt/qemu/<vm-name>.log
```

### Useful one-liners

```bash
# Get IP address of a running VM
virsh domifaddr <vm-name>

# Display VM VNC/SPICE port
virsh vncdisplay <vm-name>

# Dump full XML of a VM
virsh dumpxml <vm-name>

# Find all qcow2 images
find /var/lib/libvirt/images -name "*.qcow2" -ls
```

---

*Guide written for virt-manager 4.x / libvirt 9.x — commands are stable across recent releases of Ubuntu 22.04+, Fedora 38+, and Arch Linux.*
