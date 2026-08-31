# Windows Autopilot Registration Guide
### Noviflora Holland B.V. — IT Department
**Last updated:** April 2026  
**Authored by:** IT Team  
**Applies to:** All new Windows devices being enrolled into Intune via Autopilot

---

## Overview

This guide documents the full setup and daily-use process for registering devices into Windows Autopilot for Noviflora Holland B.V. It covers the one-time infrastructure setup (App Registration in Entra ID), how the registration script works, how to use it on a fresh device, and known issues encountered during testing with their fixes.

### What Autopilot Does

When a device is registered in Autopilot and a user signs in with their Noviflora Microsoft 365 account, Intune automatically applies:
- Company apps
- Security policies
- Compliance rules
- Group memberships

No manual imaging, no GPO fiddling, no hands-on configuration. The device sets itself up.

### What the Script Does

The script replaces the old interactive login flow (browser popup, admin credentials required) with a fully silent authentication using an Entra ID App Registration. A tech can run it straight out of the box on a fresh device with zero admin interaction.

```
Power on device → OOBE screen
        ↓
Shift + F10 → Command Prompt
        ↓
Run script
        ↓
Silent auth to Microsoft Graph (no browser, no popup)
        ↓
Duplicate check (skips if already registered)
        ↓
Hardware hash collected
        ↓
Device registered to Autopilot with Group Tag: eXcite AADJ
        ↓
Reboot → Welcome to Noviflora Holland B.V.!
```

---

## Part 1 — One-Time Setup (Admin Only)

This section only needs to be done once. It has already been completed. It is documented here for reference and disaster recovery.

### 1.1 Create the App Registration in Entra ID

1. Go to [portal.azure.com](https://portal.azure.com)
2. Navigate to **Entra ID** → **App registrations** → **New registration**
3. Set the following:
   - **Name:** `novi-intune`
   - **Supported account types:** Single tenant
   - **Redirect URI:** Leave blank
4. Click **Register**
5. On the overview page, copy and save:
   - **Application (Client) ID**
   - **Directory (Tenant) ID**

> These values are already baked into the script. This step is for reference only.

---

### 1.2 Generate a Client Secret

1. Inside the App Registration → **Certificates & secrets** → **New client secret**
2. Set:
   - **Description:** `Autopilot Script Secret`
   - **Expiry:** 12 months
3. Click **Add**
4. **Copy the Value immediately** — it is only shown once
5. Store it in the IT password manager (Keeper/1Password)

> **Rotation reminder:** The secret expires April 2027. Set a calendar reminder to rotate it before then. Update the script and password manager entry at rotation time.

---

### 1.3 Assign API Permissions

1. Inside the App Registration → **API permissions** → **Add a permission**
2. Select **Microsoft Graph** → **Application permissions**
3. Search for and add: `DeviceManagementServiceConfig.ReadWrite.All`
4. Click **Grant admin consent for Noviflora Holland B.V.**
5. Confirm the Status column shows a green **✓ Granted**

> **Critical:** Without admin consent granted, the script will authenticate successfully but receive a `403 Forbidden` when it tries to read or write Autopilot device records. The permission must show green before the script will work.

---

### 1.4 App Registration Values (Already in Script)

| Field         | Value                                  |
| ------------- | -------------------------------------- |
| Tenant ID     | `39aabbea-2938-4cf8-b94c-c78093a65c43` |
| Client ID     | `694db01f-2c0b-457b-ae50-e09fa2f1dd77` |
| Client Secret | Stored in IT password manager          |
| Group Tag     | `eXcite AADJ`                          |

---

## Part 2 — The Script

The script is stored on the IT network share. Restrict read access to IT staff only — it contains the Client Secret.

### 2.1 What It Does Step by Step

1. Checks internet connectivity to `graph.microsoft.com`
2. Installs NuGet provider if not present
3. Installs `Get-WindowsAutoPilotInfo` module if not present
4. Collects device serial number and hostname
5. Authenticates silently to Microsoft Graph using the App Registration
6. Waits 15 seconds for the session to stabilise
7. Checks if the device serial is already registered in Autopilot (skips if duplicate)
8. Collects the hardware hash and registers the device with Group Tag `eXcite AADJ`
9. Logs everything to `C:\Windows\Temp\AutopilotEnrollment.log`
10. Displays a green REGISTRATION COMPLETE banner

### 2.2 Key Technical Decisions

**Why App Registration instead of interactive login?**  
The old script popped up a browser window asking for Intune admin credentials every time. This meant a tech either needed admin access themselves or had to wait for someone who did. The App Registration acts as a service account — it authenticates silently using a Client ID and Secret with no human interaction required.

**Why are credentials passed to `Get-WindowsAutoPilotInfo.ps1` directly?**  
The tool has its own internal `Connect-MgGraph` call. Without passing credentials explicitly via `-AppId`, `-AppSecret`, and `-TenantId`, it falls back to WAM (Web Account Manager) and pops up an interactive login window — defeating the entire purpose. Passing the credentials directly bypasses this.

**Why is WAM explicitly disabled?**  
`Set-MgGraphOption -DisableLoginByWAM $true` is called before authentication as a belt-and-braces measure to prevent any WAM popup from appearing even if something tries to trigger one.

---

## Part 3 — Daily Use: Registering a Device

### 3.1 Prerequisites

- Device must be connected to the internet (WiFi or ethernet)
- You need access to the IT network share where the script lives
- No admin credentials required — the script handles auth silently

### 3.2 Step-by-Step Registration

**Step 1 — Power on the device**  
Let it boot to the OOBE screen ("Let's set things up for your organisation" or the language selection screen). **Stop here. Do not proceed through setup.**

**Step 2 — Connect to internet**  
If on WiFi, use the network icon in the bottom right of the OOBE screen to connect. If on ethernet, it should connect automatically.

**Step 3 — Open Command Prompt**  
Press **Shift + F10** on the keyboard. A black Command Prompt window will appear.

**Step 4 — Launch PowerShell with execution bypass**
```cmd
powershell -ExecutionPolicy Bypass
```

**Step 5 — Run the script**  
From network share:
```powershell
\\yourshare\IT\AutopilotRegistration.ps1
```
From USB (fallback):
```powershell
E:\AutopilotRegistration.ps1
```

**Step 6 — Wait**  
The script runs fully automatically. Do not close the window. Expected runtime is 2-3 minutes. You will see:
```
REGISTRATION COMPLETE
Group Tag  : eXcite AADJ
Serial No  : <device serial>
Log saved  : C:\Windows\Temp\AutopilotEnrollment.log
Press any key to exit...
```

**Step 7 — Reboot**  
Press any key to exit, then reboot:
```powershell
Restart-Computer
```

**Step 8 — Confirm Autopilot profile**  
After reboot, the OOBE screen should show:
> **Welcome to Noviflora Holland B.V.!**  
> Enter your Noviflora Holland B.V. email.

If this appears — registration is successful. Hand the device to the user and have them sign in with their Noviflora Microsoft 365 account.

### 3.3 Verify in Intune (Optional Sanity Check)

Go to **Intune portal** → **Devices** → **Windows** → **Windows enrollment** → **Devices (Autopilot)**  
Search the device serial number — it should appear with Group Tag `eXcite AADJ`.

---

## Part 4 — Known Issues and Fixes

These were all encountered and resolved during testing on 27 April 2026.

---

### Issue 1 — WAM Popup Appears During Registration

**Symptom:** A "Sign in" window appears mid-script asking for Microsoft account or Work/School account credentials.

**Cause:** `Get-WindowsAutoPilotInfo.ps1` has its own internal `Connect-MgGraph` call which defaults to WAM (Web Account Manager) interactive login if credentials are not passed explicitly.

**Fix applied in script:**
```powershell
Set-MgGraphOption -DisableLoginByWAM $true

Get-WindowsAutoPilotInfo.ps1 -Online -GroupTag $GroupTag `
    -AppId $ClientId `
    -AppSecret $ClientSecret `
    -TenantId $TenantId
```
Credentials are now passed directly and WAM is explicitly disabled. This popup should no longer appear.

**If it appears anyway:** Close the popup with X and check the log file for auth errors. The script may need re-running.

---

### Issue 2 — Wrong Company Branding After Reboot (UUID Collision)

**Symptom:** After registration and reboot, the OOBE screen shows another company's branding (e.g. "Welcome to SAP SE!" or "Welcome to HeelerCloud!").

**Cause:** The device's hardware UUID matches one already registered in another company's Autopilot tenant. Microsoft looks up the UUID and assigns whichever profile it finds first. This is most common with:
- Virtual machines using default or placeholder UUIDs
- Refurbished/second-hand hardware with prior Autopilot registration

**Fix for VMs (Proxmox):**  
Generate a unique UUID and set a custom serial number before registering:
```bash
qm set <VMID> -smbios1 uuid=$(cat /proc/sys/kernel/random/uuid),serial=CUSTOMSERIAL001
```
Rules for the serial number: alphanumeric only, no hyphens, no spaces, no special characters.

**Fix for physical hardware:**  
Contact the supplier and request that any prior Autopilot registration is removed from the previous tenant before the device is shipped.

---

### Issue 3 — Admin Consent Not Granted

**Symptom:** Script authenticates successfully but fails when querying or writing Autopilot device records. Error contains `403` or `Forbidden`.

**Cause:** The API permission `DeviceManagementServiceConfig.ReadWrite.All` was added but admin consent was not granted (shown as a warning triangle in the portal).

**Fix:**  
Go to **Entra ID** → **App registrations** → `Autopilot-Script-ServiceAccount` → **API permissions**  
Click **Grant admin consent for Noviflora Holland B.V.** → confirm Yes  
Status must show green ✓ before the script will work.

---

### Issue 4 — Duplicate Device Warning

**Symptom:** Script outputs `!! DUPLICATE DETECTED !!` and exits without registering.

**Cause:** The device serial number is already present in the Autopilot portal. This is working as intended — the script protects against duplicate entries.

**Fix:**  
If the device is legitimately already registered and the Autopilot profile is not being assigned, check in Intune:
- Verify the Group Tag is `eXcite AADJ`
- Verify the dynamic group membership rules are matching correctly
- Check profile assignment in **Autopilot** → **Deployment Profiles**

If the existing registration is stale or from a previous test, delete it in the Intune Autopilot devices list and re-run the script.

---

### Issue 5 — Execution Policy Blocks Script

**Symptom:** Script fails to run with an error about execution policy.

**Cause:** Fresh Windows installations default to `Restricted` execution policy.

**Fix:** Always launch PowerShell with:
```cmd
powershell -ExecutionPolicy Bypass
```

---

### Issue 6 — Network Share Not Accessible in OOBE

**Symptom:** Script path on network share returns an access denied or path not found error.

**Cause:** OOBE runs as `defaultuser0` which has no domain credentials and cannot authenticate to shares requiring a login.

**Fix:** Either configure the share to allow anonymous read for IT staff machines, or keep a USB copy of the script as a fallback.

---

## Part 5 — Troubleshooting

### Check the Log File

Every run writes a timestamped log to:
```
C:\Windows\Temp\AutopilotEnrollment.log
```
This is the first place to look if anything goes wrong. Every step is logged with INFO, SUCCESS, WARNING, or ERROR.

### Sync Delay

After successful registration, Intune needs time to sync the device and assign the Autopilot profile. This typically takes 15-30 minutes. If the OOBE screen shows generic Windows setup instead of Noviflora branding immediately after reboot, wait on that screen for 15-30 minutes and reboot again.

### Reseller / Bulk Registration

For bulk purchases from approved resellers, devices can be pre-registered into Autopilot at the warehouse before shipping. Provide the reseller with the Noviflora **Tenant ID** and request Zero Touch Deployment / Autopilot pre-registration. This bypasses the script entirely — devices arrive ready to go.

---

## Part 6 — Maintenance

| Task | Frequency | Action |
|---|---|---|
| Rotate Client Secret | Annually (before April 2027) | Generate new secret in Entra ID, update script and password manager, notify IT team |
| Review API permissions | Annually | Remove any unused permissions from the App Registration |
| Update script | As needed | Test on a VM before deploying to network share |

---

## Appendix — Script Location and Access

| Item | Details |
|---|---|
| Script location | IT network share — IT staff read access only |
| Log file | `C:\Windows\Temp\AutopilotEnrollment.log` on each enrolled device |
| Intune portal | [intune.microsoft.com](https://intune.microsoft.com) |
| Azure portal | [portal.azure.com](https://portal.azure.com) |
| App Registration name | `Autopilot-Script-ServiceAccount` |
| Secret stored in | IT password manager (Keeper/1Password) |
