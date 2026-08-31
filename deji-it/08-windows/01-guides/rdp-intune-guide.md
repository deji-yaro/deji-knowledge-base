# RDP Setup Guide for Intune-Managed Devices

> Applies to: Windows 10/11, Azure AD joined, Intune managed VMs (e.g. Proxmox hosted)  
> Covers: direct IP connection and Cloudflare Tunnel setups

---

## Overview

Connecting via RDP to an Azure AD / Intune managed VM is more complex than a standard domain-joined machine. Several layers can block you independently:

1. Firewall rules (ICMP, port 3389)
2. RDP not enabled on the VM
3. User not in Remote Desktop Users group
4. Network Level Authentication (NLA) blocking Azure AD credentials
5. NTLM fallback breaking Azure AD authentication
6. Tunnel routing preventing correct Azure AD device resolution

Work through the sections in order. If connecting via Cloudflare Tunnel, also follow Section 7.

---

## 1. Enable ICMP (Ping) via Windows Firewall

Intune policies often disable all inbound firewall rules by default, including ping.

### Via GUI (`wf.msc`)

1. Press `Win + R`, type `wf.msc`, hit Enter
2. Click **Inbound Rules** in the left panel
3. Find the following rules (filter by group "File and Printer Sharing"):
   - `File and Printer Sharing (Echo Request - ICMPv4-In)` — **Domain**
   - `File and Printer Sharing (Echo Request - ICMPv4-In)` — **Private**
4. Right-click each → **Enable Rule**

### Via PowerShell

```powershell
Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-In"
```

> ⚠️ If rules revert after a policy sync, Intune is overriding local settings. Fix must be applied from **Intune Portal → Endpoint Security → Firewall**.

---

## 2. Enable RDP on the VM

### Via GUI (`sysdm.cpl`)

1. Press `Win + R`, type `sysdm.cpl`, hit Enter
2. Go to the **Remote** tab
3. Select **"Allow remote connections to this computer"**
4. Click **OK**

### Verify via Registry

```powershell
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections
```

Expected result: `0x0` (RDP enabled)

If value is `0x1`, fix it:

```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
```

### Verify RDP Port (should be 3389)

```powershell
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber
```

Expected: `0xd3d` (3389 in hex)

---

## 3. Enable Port 3389 in Windows Firewall

### Via GUI (`wf.msc`)

1. Press `Win + R`, type `wf.msc`, hit Enter
2. Click **Inbound Rules**
3. Find and enable:
   - `Remote Desktop - User Mode (TCP-In)` — All profiles
   - `Remote Desktop - User Mode (UDP-In)` — All profiles
4. Right-click each → **Enable Rule**

### Via PowerShell

```powershell
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

### Verify RDP is Listening

```powershell
netstat -an | findstr 3389
```

Expected output:
```
TCP    0.0.0.0:3389    0.0.0.0:0    LISTENING
```

If port is not listening despite correct config, **reboot the VM**:

```powershell
Restart-Computer -Force
```

> ℹ️ On Intune-managed devices the Terminal Services stack can enter a broken state. A reboot resolves this reliably.

---

## 4. Add User for Remote Login (Azure AD Joined Device)

On Azure AD / Intune joined machines, traditional domain user lookup via `lusrmgr.msc` will not work — the Locations picker only shows the local machine, not the domain.

### Via PowerShell (correct method)

```powershell
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "dpakula@noviflora.nl"
```

Replace `dpakula@noviflora.nl` with the user's full UPN.

### Verify the user was added

```powershell
Get-LocalGroupMember -Group "Remote Desktop Users"
```

Expected output:
```
ObjectClass  Name               PrincipalSource
-----------  ----               ---------------
User         NOVIFLORA\dpakula  AzureAD
```

> ℹ️ `net localgroup` does not resolve AzureAD accounts — always use `Add-LocalGroupMember` for Intune/AzureAD joined devices.

---

## 5. Disable Network Level Authentication (NLA)

NLA authenticates the user *before* the RDP session is established. On Azure AD joined devices, NLA cannot validate Azure AD credentials when connecting from a non-enrolled machine — it fails before you even reach the Windows login screen, producing a "logon attempt failed" error.

> ℹ️ **Diagnostic signal:** If RDP works from a machine where the user is already signed in with their Azure AD account, but fails from all other machines, NLA is the cause. The enrolled machine silently passes its existing Kerberos token; unenrolled machines have no token and fail.

### Disable NLA via Registry (most reliable)

Run on the VM:

```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f
```

Verify:

```powershell
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication
```

Expected: `0x0`

Then restart the RDP service to apply without a full reboot:

```powershell
Restart-Service TermService -Force
```

### Disable NLA via WMI (alternative)

```powershell
(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-Tcp'").SetUserAuthenticationRequired(0)
```

> ⚠️ This command returns a blank `ReturnValue` on some Intune-managed devices even when it succeeds. Always verify via registry query above rather than trusting the WMI output.

---

## 6. Connect via RDP Client (Direct IP)

When connecting directly by IP (no tunnel), use the **Windows App** or **mstsc** with the following credentials:

| Field    | Value                              |
|----------|------------------------------------|
| Host     | `10.0.100.10` (VM IP)              |
| Username | `AzureAD\dpakula`                  |
| Password | Azure AD / Microsoft 365 password  |

> ℹ️ Do **not** use `NOVIFLORA\dpakula`, `dpakula@noviflora.nl`, or `NOVIFLORA\dpakula@noviflora.nl` in the RDP login prompt when connecting directly — use the `AzureAD\` prefix format.

---

## 7. Connecting via Cloudflare Tunnel

This section covers the additional steps required when RDP traffic is routed through a Cloudflare Tunnel (e.g. connecting via `localhost:3391` on the client).

### Why tunnels break Azure AD authentication

When connecting via `localhost:3391`, the RDP client sees `localhost` as the target machine name. Azure AD tries to look up that device in your tenant, fails to find it, and returns an error. Additionally, without the correct RDP file parameters, the client falls back to **NTLM authentication** — which Azure AD accounts cannot use at all. This produces failed logon events in the Security log with:

```
Authentication Package: NTLM
Status: 0xC000006D
Sub Status: 0xC0000064
```

You can confirm this is happening on the VM with:

```powershell
Get-WinEvent -LogName Security -MaxEvents 50 | Where-Object {$_.Id -eq 4625} | Format-List TimeCreated, Message
```

If you see `Authentication Package: NTLM` in the output, follow the steps below.

### Step 1 — Get the VM's actual hostname

Run on the VM:

```powershell
$env:COMPUTERNAME
```

Note this value — you will need it in the next steps.

### Step 2 — Add the VM hostname to the hosts file on the connecting machine

This makes the VM's real hostname resolve to `127.0.0.1` (through the Cloudflare Tunnel), so the RDP client connects using the correct device identity rather than `localhost`.

Run PowerShell **as Administrator** on the connecting machine:

```powershell
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "127.0.0.1    ACTUAL-VM-HOSTNAME"
```

Verify:

```powershell
Get-Content "C:\Windows\System32\drivers\etc\hosts"
```

The new line should appear at the bottom.

### Step 3 — Create a .rdp file with Azure AD auth parameters

Save a text file as `noviflora-vm.rdp` with the following content, replacing `ACTUAL-VM-HOSTNAME` with the real computer name from Step 1:

```
full address:s:ACTUAL-VM-HOSTNAME:3391
targetisaadjoined:i:1
enablerdsaadauth:i:1
authentication level:i:0
prompt for credentials:i:1
```

Key parameters explained:
- `full address` — uses the real hostname (now resolving to `127.0.0.1` via hosts file) so Azure AD can look it up correctly
- `targetisaadjoined:i:1` — tells the RDP client the target is Azure AD joined
- `enablerdsaadauth:i:1` — forces Azure AD authentication instead of NTLM/Kerberos
- `authentication level:i:0` — disables certificate warnings for the tunnel connection

### Step 4 — Connect

Double-click the `.rdp` file. When prompted, sign in with:

```
dpakula@noviflora.nl
```

You will be prompted for your password and MFA/OTP. After completing this, the session should open successfully.

---

## 8. Verify Connectivity from Linux (nc)

Before attempting RDP, confirm port 3389 is reachable:

```bash
nc -zv 10.0.100.10 3389
```

Expected output:
```
Connection to 10.0.100.10 3389 port [tcp/ms-wbt-server] succeeded!
```

---

## Troubleshooting Summary

| Symptom | Cause | Fix |
|---|---|---|
| Ping fails, VM can ping others | ICMPv4 inbound rules disabled | Enable Echo Request rules in `wf.msc` |
| Port 3389 not reachable | RDP firewall rules disabled | Enable Remote Desktop rules in `wf.msc` |
| `netstat` doesn't show 3389 | TermService in broken state | Reboot the VM |
| "User not authorized for remote login" | User not in Remote Desktop Users group | `Add-LocalGroupMember` with UPN |
| Can't find domain user in `lusrmgr.msc` | Device is Azure AD joined, not domain joined | Use `Add-LocalGroupMember -Member "user@domain.com"` |
| Firewall rules revert after policy sync | Intune overriding local rules | Configure rules in Intune Portal → Endpoint Security |
| "Logon attempt failed" — works from enrolled machine only | NLA blocking Azure AD credentials from unenrolled machines | Disable NLA via registry (Section 5) |
| "Logon attempt failed" via tunnel — Security log shows NTLM | RDP client falling back to NTLM through tunnel | Use hosts file + `.rdp` file with Azure AD auth params (Section 7) |
| Error: "target device identifier localhost not found in tenant" | Azure AD resolving tunnel address (`localhost`) instead of real hostname | Add VM hostname to hosts file on connecting machine (Section 7) |
| WMI `SetUserAuthenticationRequired` returns blank `ReturnValue` | WMI namespace restricted on Intune-managed device | Verify via registry query; use registry method as fallback |
