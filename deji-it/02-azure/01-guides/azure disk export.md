# Azure Disk Export & Local Download Guide

A step-by-step guide to exporting managed disks from Azure and downloading them to a local directory.

---

## Prerequisites

- Access to the Azure Portal with sufficient permissions on the VM and disk resources
- [AzCopy v10](https://aka.ms/downloadazcopy-v10-windows) installed locally
- Enough free local disk space (equal to the **full provisioned size** of the disk, not just used space)

---

## Step 1 — Deallocate the VM

> ⚠️ **Critical:** Always stop the VM before exporting. Exporting a running VM's disk risks a corrupted image.

1. Go to your VM in the Azure Portal
2. Click **Stop** in the top action bar
3. Wait until the status shows **"Stopped (deallocated)"**

---

## Step 2 — Generate a SAS Export URL

1. In the Azure Portal, navigate to **Disks** (either via your VM's left menu, or search globally)
2. Click on the disk you want to export
3. Click **"Export"** in the top menu bar
4. Set a SAS expiry duration — recommended: **3–12 hours** depending on disk size and connection speed
5. Click **"Generate URL"**
6. Copy the generated SAS URL — keep it safe and do not share it

Repeat this process for each disk (OS disk, data disk, etc.).

---

## Step 3 — Install AzCopy

### Windows
Download from: https://aka.ms/downloadazcopy-v10-windows

Extract the `.zip` and either run `azcopy.exe` from that folder, or move it to a directory in your system PATH.

### Linux
```bash
wget https://aka.ms/downloadazcopy-v10-linux -O azcopy.tar.gz
tar -xzf azcopy.tar.gz
sudo mv azcopy_linux_amd64_*/azcopy /usr/local/bin/
```

---

## Step 4 — Download the Disk

### Windows (PowerShell or CMD)

Create the destination directory if it doesn't exist:
```powershell
mkdir C:\exports
```

Download the disk:
```powershell
azcopy copy "<SAS_URL>" "C:\exports\os-disk.vhd" --blob-type PageBlob --check-md5=NoCheck
```

### Linux

```bash
azcopy copy "<SAS_URL>" "/your/target/directory/os-disk.vhd" --blob-type PageBlob
```

> Replace `<SAS_URL>` with the full URL generated in Step 2 (keep the quotes — the URL is long and contains special characters).

---

## Step 5 — Verify Free Space Before Downloading

### Windows
```powershell
Get-PSDrive -PSProvider FileSystem
```

### Linux
```bash
df -h /your/target/directory
```

Make sure available space is **at least equal to the provisioned disk size** in Azure (e.g. a 256 GB disk requires 256 GB free, even if only 40 GB is used).

---

## Resume an Interrupted Download

If the download is interrupted, resume it using the Job ID shown in the AzCopy output:

```powershell
azcopy jobs resume <JOB_ID>
```

Example:
```powershell
azcopy jobs resume 3b56e414-75a8-6d4a-4dda-b97533c8a035
```

---

## Using the Downloaded VHD On-Prem

| Target Environment | Action |
|---|---|
| **Hyper-V** | Attach `.vhd` directly when creating a new VM |
| **VMware (ESXi/vSphere)** | Convert: `qemu-img convert -f vpc -O vmdk os-disk.vhd os-disk.vmdk` |
| **Proxmox** | Convert: `qemu-img convert -f vpc -O qcow2 os-disk.vhd os-disk.qcow2` |
| **Bare metal** | Use `qemu-img` + `dd` to write image to physical disk |

---

## Troubleshooting

### ❌ "Export not supported for this disk"

**Cause:** The disk is using an unsupported configuration for direct export — most commonly caused by **Trusted Launch** or **Confidential VM** security type.

**Fix:**
1. Go to the disk → **"Create snapshot"** (select Full snapshot)
2. From the snapshot → **"Create Disk"** → set Security type to **"Standard"** (removes Trusted Launch)
3. Export the newly created standard disk instead — this will work

Alternatively, try exporting via Azure CLI:
```bash
az disk grant-access \
  --resource-group <your-rg> \
  --name <disk-name> \
  --duration-in-seconds 14400 \
  --access-level Read
```

---

### ❌ "There is not enough space on the disk"

**Cause:** AzCopy pre-allocates the full provisioned VHD size before downloading. Your destination drive doesn't have enough free space.

**Fix:** Point the download to a drive with sufficient free space:
```powershell
azcopy copy "<SAS_URL>" "D:\exports\os-disk.vhd" --blob-type PageBlob
```

Check available space first:
```powershell
Get-PSDrive -PSProvider FileSystem
```

---

### ❌ "Disk is attached to a running VM"

**Cause:** The VM was not fully deallocated before attempting export.

**Fix:** Go to the VM in the Portal → **Stop** → wait for status **"Stopped (deallocated)"** → retry export.

---

### ❌ Download stuck at 0.0% for a long time

**Cause:** This is normal behaviour. AzCopy pre-allocates the full disk size on your local drive before beginning the actual data transfer. For large disks (128 GB+) this can take several minutes.

**Fix:** Wait — progress will begin moving once pre-allocation completes. Do not close the terminal.

---

### ❌ SAS URL expired during download

**Cause:** The SAS URL has a time limit set during generation.

**Fix:** Go back to the disk in Azure Portal → Export → generate a new SAS URL → re-run the AzCopy command with the new URL. If the file already partially downloaded, AzCopy will resume from where it left off.

---

### ❌ "Access denied / insufficient permissions"

**Cause:** Your Azure account lacks the required role on the disk resource.

**Fix:** Ensure your account has at least the **"Disk Export"** or **"Contributor"** role on the disk or resource group. Ask your Azure administrator to grant access via IAM.

---

## Post-Migration Notes

After booting the VM on-prem, keep these in mind:

- **Azure VM Agent** — Uninstall `WindowsAzureGuestAgent` as it will throw errors without the Azure fabric
- **Networking** — The NIC will reference Azure's virtual network; update IP and DNS settings for your on-prem environment
- **Windows Licensing** — Azure KMS activation will stop working on-prem; ensure you have a valid on-prem KMS server or retail license
