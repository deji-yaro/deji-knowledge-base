# Add On-Prem SMTP IP to Microsoft Defender Anti-Spam (GUI)

## Purpose
Whitelist your on-prem SMTP server's public IP in Microsoft 365 to prevent spam filtering and reduce external sender warnings.

---

## Prerequisites
- **Global Admin** or **Security Admin** role
- Public IP address of your MailEnable server

---

## Steps

### 1. Get Your SMTP Server's Public IP
From your on-prem server:
- Open a browser and visit: `https://ifconfig.me`
- Or run in CMD/PowerShell: `curl ifconfig.me`
- Note the IPv4 address returned

### 2. Access Microsoft Defender Portal
1. Go to **[security.microsoft.com](https://security.microsoft.com)**
2. Sign in with your admin account (`admin@plsnordic.dk`)

### 3. Navigate to Connection Filter Policy
1. In the left menu, go to **Email & collaboration** → **Policies & rules**
2. Click **Threat policies**
3. Under **Anti-spam**, click **Connection filter policy (IP allow/deny list)**

### 4. Edit the Default Policy
1. You’ll see the **Default** policy — click it
2. In the flyout panel, click **Edit connection filter policy**

### 5. Add Your IP to the Allow List
1. Scroll to the **IP allow list** section
2. Click **+ Add IP addresses**
3. Enter your SMTP server’s public IP (e.g., `203.0.113.50`)
4. Click **Add**
5. Click **Save** at the bottom of the panel

### 6. Wait for Propagation
- Changes take **30–60 minutes** to apply across Microsoft 365
- No reboot or service restart needed

---

## If the Yellow Banner Persists

The yellow "external sender" banner is **not controlled by anti-spam policies**. It’s a separate feature called **External Sender Warning**.

### Disable External Sender Warning (GUI)

1. Go to **[admin.microsoft.com](https://admin.microsoft.com)**
2. Navigate to **Settings** → **Mail** → **External sharing**
3. Look for **Show external sender warning** or similar
4. Toggle it **Off**

*Or via PowerShell if the GUI option isn’t visible:*
```powershell
Connect-ExchangeOnline
Set-ExternalInOutlook -Enabled $false
```

---

## Verification
1. Send a test email from your on-prem SMTP server to an M365 mailbox
2. Confirm:
   - Email lands in **Inbox** (not Junk)
   - No yellow banner (if you disabled external sender warning)

---

## Rollback
To remove the IP later:
1. Return to **Connection filter policy** in security.microsoft.com
2. Edit the **Default** policy
3. Find your IP in the **IP allow list**
4. Click the **X** next to it to remove
5. Click **Save**