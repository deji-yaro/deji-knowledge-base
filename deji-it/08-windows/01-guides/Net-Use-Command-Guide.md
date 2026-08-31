# Using the `net use` Command to Map Network Drives

## What is `net use`?

`net use` is a built-in Windows command that connects your machine to a shared network resource — such as an SMB share on a NAS, server, or any machine with file sharing enabled. It maps the share to a local drive letter, making it accessible just like a USB stick or local disk.

---

## Basic Syntax

```cmd
net use <drive letter>: \\<server IP or hostname>\<share name> [options]
```

---

## Common Examples

### Map a share as guest (no credentials)

```cmd
net use Z: \\[SERVER_IP]\[SHARE_NAME] /guest
```

Use this when the share allows anonymous/guest access. No username or password is required.

### Map a share with credentials

```cmd
net use Z: \\[SERVER_IP]\[SHARE_NAME] /user:[USERNAME] [PASSWORD]
```

Replace `[USERNAME]` and `[PASSWORD]` with the actual credentials for the share.

### Map a share and make it persistent (survives reboot)

```cmd
net use Z: \\[SERVER_IP]\[SHARE_NAME] /persistent:yes
```

### Map a share without a drive letter (UNC path only)

```cmd
net use \\[SERVER_IP]\[SHARE_NAME]
```

This connects to the share without assigning a drive letter. You can still access it via its UNC path directly.

### Disconnect/unmap a drive

```cmd
net use Z: /delete
```

### Disconnect all mapped drives

```cmd
net use * /delete
```

### List all currently mapped drives

```cmd
net use
```

---

## Options Reference

| Option              | Description                                          |
|---------------------|------------------------------------------------------|
| `/guest`            | Connect using the guest account (no credentials)     |
| `/user:<username>`  | Specify a username for authentication                |
| `/persistent:yes`   | Reconnect automatically after reboot                 |
| `/persistent:no`    | Do not reconnect after reboot (default)              |
| `/delete`           | Disconnect and remove the mapped drive               |
| `*`                 | Use the next available drive letter automatically    |

---

## Drive Letter Choice

You can use any available letter from A to Z. Common conventions:

| Letter | Typical Use                        |
|--------|------------------------------------|
| Z:     | Primary network share              |
| Y:     | Secondary network share            |
| S:     | Shared drives in corporate setups  |
| T:     | Temporary shares                   |

In our workflow we use **Z:** as it is unlikely to conflict with any local drives (C: system, D: CD/DVD etc).

---

## Our Specific Use Case

In the [WORKFLOW_NAME] workflow, we map the [NAS/SERVER] SMB share to Z: so the PowerShell script stored on [NAS/SERVER] can be accessed and executed directly from the Windows machine being enrolled.

### Step 1 — Map the share

```cmd
net use Z: \\[SERVER_IP]\[SHARE_NAME] /guest
```

### Step 2 — Navigate to the script

```cmd
cd Z:\[SCRIPT_PATH]
```

### Step 3 — Run the script

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\[SCRIPT_NAME].ps1
```

---

## Troubleshooting

### "The network path was not found"
- Verify the server IP is correct and reachable: `ping [SERVER_IP]`
- Verify the share name is correct
- Verify the machine running the command has network access

### "Access is denied"
- The share does not allow guest access
- Use `/user:[USERNAME] [PASSWORD]` instead of `/guest`
- Check share permissions on [NAS/SERVER]

### "The local device name is already in use"
- Drive letter Z: is already mapped to something else
- Either delete the existing mapping first: `net use Z: /delete`
- Or use a different drive letter: `net use Y: \\...`

### "System error 67 - The network name cannot be found"
- The share name is wrong or the SMB service is not running on the server
- Verify the share exists on [NAS/SERVER] under [SHARE_MANAGEMENT_PATH]

### Drive not available after reboot
- Add `/persistent:yes` to the command
- Or re-run the `net use` command after each reboot (our workflow does this manually each time which is fine for [WORKFLOW_DESC] purposes)

---

## Summary

| Task                       | Command                                                             |
| -------------------------- | ------------------------------------------------------------------- |
| Map share as guest         | `net use Z: \\[SERVER_IP]\[SHARE_NAME] /guest`                      |
| Map share with credentials | `net use Z: \\[SERVER_IP]\[SHARE_NAME] /user:[USERNAME] [PASSWORD]` |
| List mapped drives         | `net use`                                                           |
| Disconnect a drive         | `net use Z: /delete`                                                |
| Disconnect all drives      | `net use * /delete`                                                 |
