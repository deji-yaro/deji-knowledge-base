# Proxmox SMBIOS & UUID Configuration for Windows Autopilot

## Why Does This Matter?

When you create a Windows VM in Proxmox, it gets a virtual hardware identity —
just like a physical machine has a manufacturer label, model name, and serial
number on the bottom. Windows reads these values at boot and uses them to
identify the device.

For **Windows Autopilot**, Microsoft collects a "hardware hash" — a fingerprint
built from the device's hardware identifiers including the **serial number**.
If that serial number is blank or null, the registration fails entirely.
If it was previously seen in another tenant, Microsoft blocks it with a
`ZtdDeviceAssignedToOtherTenant` error.

This is why setting a proper, unique SMBIOS identity on every Proxmox VM
intended for Autopilot is critical.

---

## What is SMBIOS?

**SMBIOS** (System Management BIOS) is a standard that defines how firmware
exposes hardware information to the operating system. It contains structured
data tables describing the system — manufacturer, product name, serial number,
UUID, and more.

In Proxmox, the `-smbios1` parameter lets you inject custom SMBIOS Type 1
(System Information) values into a VM, overriding the defaults.

---

## What is a UUID?

A **UUID** (Universally Unique Identifier) is a 128-bit value used to uniquely
identify something — in this case, a virtual machine. It looks like this:

```
12345678-abcd-ef12-3456-789abcdef012
```

Proxmox assigns a UUID to every VM automatically, but when cloning or
re-registering devices, you may need to generate and assign a fresh one to
avoid identity conflicts in Microsoft's systems.

---

## The uuidgen Command

`uuidgen` is a Linux command line tool that generates a new random UUID every
time it is called.

### Install it

```bash
apt install uuid-runtime -y
```

### Basic usage

```bash
uuidgen
# Output example: a3f1c2d4-1234-5678-abcd-ef1234567890
```

### Use it inline inside another command

The `$()` syntax in bash executes a command and substitutes its output inline:

```bash
qm set 390 -smbios1 "serial=PVEVM390,uuid=$(uuidgen)"
```

This generates a fresh UUID and passes it directly into the qm command in one
step, without needing to copy/paste it manually.

---

## The qm set -smbios1 Command

`qm` is the Proxmox command line tool for managing QEMU virtual machines.
The `-smbios1` flag sets the SMBIOS Type 1 (System Information) fields.

### Syntax

```bash
qm set <VMID> -smbios1 "key=value,key=value,..."
```

### Available keys

| Key          | Description                                      | Example            |
|--------------|--------------------------------------------------|--------------------|
| serial       | Serial number of the virtual machine             | PVEVM390           |
| uuid         | Unique identifier for the VM                     | $(uuidgen)         |
| manufacturer | Manufacturer name shown to Windows               | Microsoft          |
| product      | Product/model name shown to Windows              | VirtualMachine     |
| version      | Version string                                   | 1.0                |
| sku          | SKU number                                       | SKU001             |
| family       | Product family                                   | Cloud              |

### Important formatting rules

Proxmox is strict about the serial number format:

- **No hyphens** — `PVE-VM-390` will fail, use `PVEVM390`
- **No spaces** — `Virtual Machine` will fail, use `VirtualMachine`
- **Alphanumeric only** for the serial field

---

## Practical Examples

### Set serial number only (minimum for Autopilot)

```bash
qm set 390 -smbios1 "serial=PVEVM390"
```

### Set serial and fresh UUID (recommended for Autopilot)

```bash
qm set 390 -smbios1 "serial=PVEVM390,uuid=$(uuidgen)"
```

### Set full SMBIOS identity

```bash
qm set 390 -smbios1 "manufacturer=Microsoft,product=VirtualMachine,serial=PVEVM390,uuid=$(uuidgen)"
```

### Verify the setting was applied

```bash
qm config 390 | grep smbios
# Output: smbios1: serial=PVEVM390,uuid=a3f1c2d4-...
```

---

## Naming Convention Recommendation

For a fleet of Autopilot VMs, use a consistent serial number naming scheme
so devices are easily identifiable in Intune:

| VM ID | Serial Number  | Purpose              |
|-------|----------------|----------------------|
| 390   | PVEVM390       | Test VM              |
| 391   | PVEVM391       | Dev VM               |
| 400   | PVEVM400       | Autopilot test fleet |

This makes it easy to cross-reference a device in Intune with its Proxmox VM ID.

---

## Why We Hit the ZtdDeviceAssignedToOtherTenant Error

During our Autopilot registration process, the script ran twice:

1. **First run (OOBE)** — authenticated partially, likely uploaded the hardware
   hash but failed mid-way due to the `defaultuser0` Windows Security prompt
2. **Second run (desktop)** — tried to register the same hash again

Microsoft's ZTD (Zero Touch Deployment) service saw the hash had already been
submitted and flagged it as belonging to another tenant, blocking the second
registration entirely.

### Fix

Generate a new UUID to change the VM's hardware fingerprint, then clear the
partial registration from Intune before re-registering:

```bash
qm set 390 -smbios1 "serial=PVEVM390,uuid=$(uuidgen)"
```

This gives the VM a fresh identity that Microsoft has never seen before,
allowing a clean Autopilot registration.

---

## Summary

| Command                        | Purpose                                      |
|--------------------------------|----------------------------------------------|
| `apt install uuid-runtime -y`  | Install the uuidgen tool                     |
| `uuidgen`                      | Generate a random UUID                       |
| `qm set <ID> -smbios1 "..."`   | Set SMBIOS identity fields on a Proxmox VM   |
| `qm config <ID> | grep smbios` | Verify SMBIOS settings on a VM               |

Always set a unique serial number and UUID on any Proxmox VM before running
Windows Autopilot registration to avoid identity conflicts in Microsoft's
ZTD service.
