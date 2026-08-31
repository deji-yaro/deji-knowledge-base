# Dell PowerEdge R630 Firmware Update Guide

A practical guide for updating iDRAC, BIOS, and RAID controller firmware on a PowerEdge R630 running Proxmox (or any Linux-based hypervisor). Written from real-world experience — including every dead end.

---

## Prerequisites

Before starting, confirm you have:

- iDRAC IP address and admin credentials
- Proxmox (or OS) IP address and root SSH access
- A workstation on the same network as the server
- Internet access on both the workstation and the server
- ~500MB free space on the server for temporary files

---

## 1. Accessing the iDRAC Web UI

Open a browser and navigate to `https://<idrac-ip>`. Accept the self-signed certificate warning and log in with your admin credentials.

The iDRAC web UI is your primary control panel for firmware updates. Key sections you will use:

- **Overview → Server → Logs** — job queue and update history
- **iDRAC Settings → Update and Rollback** — firmware update interface
- **Virtual Console** — remote screen access for BIOS/Lifecycle Controller

---

## 2. Verify Current Firmware Versions

Before updating anything, document what you have. SSH into iDRAC directly:

```bash
ssh admin@<idrac-ip>
```

Then run:

```racadm
racadm getsysinfo
```

Note down the **Firmware Version** under RAC Information. Also run:

```racadm
racadm getniccfg
```

This shows the actual link speed of the LOM ports — useful for baseline comparison. The iDRAC web UI may display incorrect speeds (a known display bug in older firmware), but `getniccfg` reports ground truth.

To verify the OS-level NIC speed independently, SSH into Proxmox and run:

```bash
ethtool eno1
```

The `Speed:` field here is the definitive value reported by the kernel directly from hardware registers.

---

## 3. Finding the Right Firmware Packages

Go to [Dell Support](https://dell.com/support) and enter your server's **Service Tag** (found on the front bezel or via `racadm getsysinfo`).

Navigate to **Drivers & Downloads** and filter by category. The packages you need are:

| Component | Category to Filter | Package Name to Look For |
|---|---|---|
| iDRAC | iDRAC with Lifecycle Controller | iDRAC-with-Lifecycle-Controller_Firmware_* |
| BIOS | BIOS | PowerEdge R630 BIOS |
| PERC H330 | Storage | Dell PERC H330 Mini/Adapter RAID Controllers firmware |
| Lifecycle Controller | Systems Management | Lifecycle Controller |

Always download the **Windows 64-bit `.exe` (DUP format)** — this is what iDRAC's web UI accepts for manual upload. Do not download `.bin`, `.tgz`, or Linux shell scripts for iDRAC web UI uploads.

---

## 4. Update Order — This Matters

Always update in this order:

1. **iDRAC first** — everything else depends on it
2. **Lifecycle Controller** — updates the F10 environment
3. **BIOS** — requires reboot
4. **PERC H330** — requires reboot
5. **NIC firmware** — requires reboot

Updating iDRAC first is critical. An outdated iDRAC will reject newer firmware packages with a RED007 signature error (see Troubleshooting section).

---

## 5. Updating iDRAC Firmware

### Normal Path (iDRAC 2.30+)

In the iDRAC web UI go to **iDRAC Settings → Update and Rollback → Update tab**:

1. Select **Local** as the file location
2. Click **Choose File** and select the `.exe` DUP downloaded from Dell
3. Click **Upload**
4. Once uploaded, tick the checkbox next to the package
5. Click **Install**

iDRAC will apply the update and restart itself. Your browser session will drop for approximately 5 minutes — this is normal. The server itself does not reboot.

### If the `.exe` DUP is Rejected (RED007 Error)

If your iDRAC is too old (pre-2.30), it cannot verify the cryptographic signatures on newer DUP packages and will reject them with:

```
RED007: Unable to verify Update Package signature.
```

In this case you need to extract the raw firmware binary from the `.exe` and upload that directly. On the Proxmox host:

```bash
apt-get install p7zip-full -y
```

Transfer the iDRAC `.exe` from your workstation to Proxmox:

```bash
scp ~/Downloads/iDRAC-with-Lifecycle-Controller_Firmware_*.EXE root@<proxmox-ip>:/tmp/
```

Extract it:

```bash
cd /tmp
7z x iDRAC-with-Lifecycle-Controller_Firmware_*.EXE
ls /tmp/payload/
```

You will find either a `firmimg.d7` (iDRAC8) or `firmimg.d9` (iDRAC9) file in the `payload` directory. Copy it back to your workstation:

```bash
scp root@<proxmox-ip>:/tmp/payload/firmimg.d7 ~/Downloads/
```

Upload `firmimg.d7` through the iDRAC web UI the same way as a normal DUP. This raw binary bypasses the signature check entirely.

---

## 6. Updating BIOS and PERC H330

Once iDRAC is updated, subsequent updates follow the same process:

1. **iDRAC Settings → Update and Rollback → Update tab**
2. Upload the `.exe` DUP
3. Click **Install** or **Install Next Reboot**

For BIOS and PERC updates, use **Install Next Reboot** if you want to batch multiple updates before rebooting. This queues the job and applies it on the next reboot rather than immediately.

When ready to apply all queued updates, reboot via **Overview → Server → Reboot**.

> **Warning:** Shut down or migrate any running Proxmox VMs before rebooting the host.

---

## 7. Using Lifecycle Controller for Bulk Updates (F10)

Once iDRAC is updated to a recent version, the Lifecycle Controller gains HTTPS support and can pull all updates directly from Dell's servers — no USB or manual downloads required.

1. Reboot the server via iDRAC
2. Have **Virtual Console** open to see the screen
3. Press **F10** during POST to enter Lifecycle Controller
4. Go to **Settings → Network Settings** and configure a valid IP/gateway
5. Go to **Firmware Update → Launch Firmware Update**
6. Select **Network Share → HTTPS**
7. Enter:
   - Share Name/Address: `downloads.dell.com`
   - File Path: `catalog`
8. Click **Next** — it will pull the full catalog and list all available updates
9. Select components and click **Apply**

This is the cleanest method when available and handles dependency ordering automatically.

---

## 8. Verifying Updates

After updates and reboot, verify via iDRAC SSH:

```racadm
racadm getsysinfo
```

Check the **Firmware Version** field. Also verify from Proxmox:

```bash
ethtool eno1
```

Confirm `Speed: 1000Mb/s` and `Link detected: yes`.

---

## Troubleshooting

### RED007: Unable to verify Update Package signature

Your iDRAC firmware is too old to verify the signature on newer DUP packages. See Section 5 for the `firmimg.d7` extraction workaround. This must be resolved before any other updates can proceed.

### iDRAC Web UI Shows 100Mbps but Server is Actually at 1Gbps

This is a display bug in older iDRAC firmware versions. The UI incorrectly reports the LOM speed. Verify actual speed via `racadm getniccfg` (shows `Speed = 1Gb/s`) or `ethtool eno1` on the OS (shows `Speed: 1000Mb/s`). Updating iDRAC firmware resolves the display bug.

### Lifecycle Controller Only Shows HTTP, Not HTTPS

Your iDRAC firmware is too old to support HTTPS in Lifecycle Controller. Dell dropped plain HTTP support for their update repositories, so this path is a dead end until iDRAC is updated. Use the `firmimg.d7` extraction method in Section 5 to bootstrap the iDRAC update first.

### Dell Direct Download URLs Return 403 Forbidden

Dell's download URLs are session-based and expire within minutes of generation. Do not copy the URL from the browser address bar after a redirect. Instead, download the file directly to your workstation via the browser, then transfer it to the server using `scp`.

### DSU (Dell System Update) Fails on Proxmox

DSU does not officially support Proxmox (Debian-based). The bootstrap script will exit with:

```
Unable to determine that you are running an OS I know about.
```

Forcing the Debian repository also tends to fail. Use the iDRAC web UI upload method instead, or Lifecycle Controller over the network once iDRAC is updated.

### USB Boot Fails in Lifecycle Controller

Lifecycle Controller requires USB drives formatted as **FAT32 with MBR partitioning**. NTFS is not supported in the UEFI environment. FAT32 has a 4GB file size limit, which makes it incompatible with the Dell SUU ISO (typically 13GB+). The network update method via `downloads.dell.com` is the practical alternative.

### NIC Firmware Package Rejected: "Component not in target system inventory"

This means the firmware package is for a different NIC model than what is installed. The R630 ships with the **Broadcom BCM5720** (NetXtreme, not NetXtreme-E). Verify your exact NIC before downloading:

```bash
lspci | grep -i ethernet
ethtool -i eno1
```

Match the chip model to the correct firmware package on Dell Support. NetXtreme and NetXtreme-E are different product lines with separate firmware packages.

---

## Quick Reference

| Task | Location in iDRAC UI |
|---|---|
| Upload & install firmware | iDRAC Settings → Update and Rollback → Update |
| View job queue | Overview → Server → Logs |
| Remote screen access | Virtual Console |
| Reboot server | Overview → Server → Power/Thermal |
| Check current firmware | SSH → `racadm getsysinfo` |
| Check NIC link speed | SSH → `racadm getniccfg` |

---

*Guide based on hands-on experience with PowerEdge R630, iDRAC8 Enterprise, Proxmox 8.x, May 2026.*
