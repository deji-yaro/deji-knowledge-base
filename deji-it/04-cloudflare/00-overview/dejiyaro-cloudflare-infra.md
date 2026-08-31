# [DOMAIN] — Cloudflare Infrastructure Overview

> Last updated: [DATE]

---

## Account & Domain

| Field | Value |
|---|---|
| Domain | `[DOMAIN]` |
| Login email | `[EMAIL]` |
| Password | Stored in [PASSWORD_MANAGER] |
| 2FA | [2FA_METHOD] |
| Expires | [EXPIRY_DATE] |
| Auto-renew | [AUTO_RENEW] |
| Annual cost | [COST] |

### SSL / TLS Certificate

| Field | Value |
|---|---|
| Type | Universal (Active) |
| Covers | `[DOMAIN]`, `*.[DOMAIN]` |
| Expires | [CERT_EXPIRY] |
| Validity period | [CERT_VALIDITY] |
| Renewal | Automatic |

---

## DNS Records

| Type   | Name                     | Content / Target                 | Proxy    | TTL   | Notes                  |
| ------ | ------------------------ | -------------------------------- | -------- | ----- | ---------------------- |
| A      | `[SUBDOMAIN_1]`          | `[IP_ADDRESS]`                   | DNS only | [TTL] | —                      |
| Tunnel | `[SUBDOMAIN_2]`          | [TUNNEL_1]                       | Proxied  | Auto  | [APP_DESC_1]           |
| Tunnel | `[SUBDOMAIN_3]`          | [TUNNEL_1]                       | Proxied  | Auto  | [APP_DESC_2]           |
| Tunnel | `[SUBDOMAIN_4]`          | [TUNNEL_2]                       | Proxied  | Auto  | [APP_DESC_3]           |
| Tunnel | `[SUBDOMAIN_5]`          | [TUNNEL_2]                       | Proxied  | Auto  | [APP_DESC_4]           |
| Tunnel | `[SUBDOMAIN_6]`          | [TUNNEL_3]                       | Proxied  | Auto  | [APP_DESC_5]           |
| Tunnel | `[SUBDOMAIN_7]`          | [TUNNEL_1]                       | Proxied  | Auto  | [APP_DESC_6]           |
| Tunnel | `[SUBDOMAIN_8]`          | [TUNNEL_1]                       | Proxied  | Auto  | [APP_DESC_7]           |
| CNAME  | `[SUBDOMAIN_9]`          | `[CNAME_TARGET_1]`               | Proxied  | Auto  | —                      |
| CNAME  | `[SUBDOMAIN_10]`         | `[CNAME_TARGET_2]`               | Proxied  | Auto  | [APP_DESC_8]           |
| CNAME  | `[SUBDOMAIN_11]`         | `[CNAME_TARGET_2]`               | Proxied  | Auto  | [APP_DESC_9]           |
| MX     | `[DOMAIN]`               | `[MX_PRIMARY]` (pri 10)          | DNS only | [TTL] | [MX_DESC_PRIMARY]      |
| MX     | `[DOMAIN]`               | `[MX_SECONDARY]` (pri 20)        | DNS only | [TTL] | [MX_DESC_SECONDARY]    |
| TXT    | `[DOMAIN]`               | `[SPF_RECORD]`                   | DNS only | Auto  | SPF record             |
| TXT    | `[DOMAIN]`               | `[VERIFICATION_RECORD]`          | DNS only | [TTL] | Domain verification    |
| CNAME  | `[DKIM_SELECTOR_1]`      | `[DKIM_TARGET_1]`                | DNS only | Auto  | DKIM key 1             |
| CNAME  | `[DKIM_SELECTOR_2]`      | `[DKIM_TARGET_2]`                | DNS only | Auto  | DKIM key 2             |
| CNAME  | `[DKIM_SELECTOR_3]`      | `[DKIM_TARGET_3]`                | DNS only | Auto  | DKIM key 3             |
| TXT    | `_dmarc`                 | `[DMARC_RECORD]`                 | DNS only | Auto  | DMARC policy           |
| TXT    | `_[SERVICE]_verify`      | `[VERIFICATION_HASH]`            | DNS only | Auto  | [SERVICE] verification |

---

## Cloudflare Tunnels

### Overview

| Tunnel         | Type        | Status    | Uptime   | Host                                   |
| -------------- | ----------- | --------- | -------- | -------------------------------------- |
| `[TUNNEL_1]`   | cloudflared | [STATUS_1] | [UPTIME_1] | [HOST_DESC_1]                          |
| `[TUNNEL_2]`   | cloudflared | [STATUS_2] | [UPTIME_2] | [HOST_DESC_2]                          |
| `[TUNNEL_3]`   | cloudflared | [STATUS_3] | [UPTIME_3] | [HOST_DESC_3]                          |

---

### [TUNNEL_1]

Installed on [HOST_DESC_1] as a [DEPLOYMENT_METHOD].

| Hostname           | Backend                 | Status     |
| ------------------ | ----------------------- | ---------- |
| `[SUBDOMAIN_7].[DOMAIN]` | `[PROTOCOL]://localhost:[PORT_1]`  | [STATUS_1A] |
| `[SUBDOMAIN_N].[DOMAIN]` | `[PROTOCOL]://localhost:[PORT_2]` | [STATUS_1B] |
| `[SUBDOMAIN_N].[DOMAIN]`   | `[PROTOCOL]://localhost:[PORT_3]` | [STATUS_1C] |

---

### [TUNNEL_2]

[HOST_DESC_2]-hosted tunnel. Currently **[STATUS_2]**. Catch-all rule returns `HTTP 404`.

| # | Hostname | Backend | Status |
|---|---|---|---|
| 1 | `[SUBDOMAIN_3].[DOMAIN]` | `[PROTOCOL]://[IP]:[PORT_4]` | [STATUS_2A] |
| 2 | `[SUBDOMAIN_2].[DOMAIN]` | `[PROTOCOL]://[IP]:[PORT_5]` | [STATUS_2B] |
| 3 | `[SUBDOMAIN_6].[DOMAIN]` | `[PROTOCOL]://[IP]:[PORT_6]` | [STATUS_2C] |
| 4 | `[SUBDOMAIN_8].[DOMAIN]` | `[PROTOCOL]://[IP]:[PORT_7]` | [STATUS_2D] |

> **Catch-all rule:** `http_status:404` — unmatched routes return 404.

---

### [TUNNEL_3]

Hosted on the [HOST_DESC_3].

| Hostname                | Service                          | Notes                                |
| ----------------------- | -------------------------------- | ------------------------------------ |
| `[SUBDOMAIN_4].[DOMAIN]`    | [SERVICE_1]                        | [SERVICE_1_NOTE]                       |
| `[SUBDOMAIN_5].[DOMAIN]` | [SERVICE_2]                        | [SERVICE_2_NOTE]                       |
| `[SUBDOMAIN_N].[DOMAIN]`    | [SERVICE_3]                        | ⛔ Not in use                         |

### [TUNNEL_4]

VM on [HOST_DESC_4] hosting [VM_DESC].

| Hostname            | Backend                | Status   |
| ------------------- | ---------------------- | -------- |
| `[SUBDOMAIN_N].[DOMAIN]` | `[PROTOCOL]://localhost:[PORT_N]` | [STATUS_4A] |

---

## Zero Trust — Access Applications

### [SUBDOMAIN_7].[DOMAIN]

| Field | Value |
|---|---|
| Application type | Self-hosted |
| Tunnel | `[TUNNEL_1]` |

**Policy: [POLICY_NAME]**

| Field            | Value                        |
| ---------------- | ---------------------------- |
| Action           | Allow                        |
| Session duration | [SESSION_DURATION]           |
| Selector         | Email                        |
| Allowed email    | `[ALLOWED_EMAIL]`            |

### [SUBDOMAIN_N].[DOMAIN]

| Field            | Value                    |
| ---------------- | ------------------------ |
| Application type | Self-hosted              |
| Tunnel           | `[TUNNEL_4]`             |

**Policy: [POLICY_NAME]**

| Field            | Value                        |
| ---------------- | ---------------------------- |
| Action           | Allow                        |
| Session duration | [SESSION_DURATION]           |
| Selector         | Email                        |
| Allowed email    | `[ALLOWED_EMAIL]`            |

---

## RDP Connection Runbook

> **Prerequisite:** The connecting machine must have `cloudflared` installed. Without it, the connection cannot be established.

### Steps (Windows client)

**1. Open a local tunnel listener**

Open PowerShell and run:

```powershell
cloudflared access rdp --hostname [SUBDOMAIN_7].[DOMAIN] --url rdp://localhost:[LOCAL_PORT]
```

**2. Authenticate in the browser**

A browser window will open. Enter the authorized email address:

```
[ALLOWED_EMAIL]
```

**3. Enter the one-time code**

A code will be sent to that email. Enter it in the browser and click **Approve**.

**4. Connect via Remote Desktop**

Open Remote Desktop Connection (`mstsc`) and connect to:

```
localhost:[LOCAL_PORT]
```

**5. Log in**

- Username: `[USERNAME]`
- Enter your password when prompted
- The [OS] desktop will appear — click [USERNAME] and enter the password again

> **Troubleshooting:** If you cannot connect from a Windows machine, open the **Experience** tab in `mstsc` and disable all checkboxes there.

---

## Email — [EMAIL_PROVIDER]

| Field | Value |
|---|---|
| Provider | [EMAIL_PROVIDER] |
| MX primary (priority 10) | `[MX_PRIMARY]` |
| MX secondary (priority 20) | `[MX_SECONDARY]` |
| SPF | ✅ Configured |
| DKIM | ✅ [DKIM_COUNT] keys active |
| DMARC | ⚠️ `[DMARC_POLICY]` |
