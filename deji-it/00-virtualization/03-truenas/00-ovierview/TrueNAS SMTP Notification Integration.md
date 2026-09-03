## Overview
TrueNAS system alerts and notifications are routed through a configured SMTP relay to ensure infrastructure monitoring reaches the administrator immediately. This integration leverages a managed SMTP service for reliable, authenticated delivery.

---

## Configuration Path

### 1. SMTP Server Configuration
**Location**: `System` > `General Settings` > `Email Options`

| Parameter | Value |
| :--- | :--- |
| **Send Mail Method** | SMTP |
| **From Email** | `alert@<yourdomain.com>` |
| **From Name** | `alert` (or desired identifier) |
| **Outgoing Mail Server** | `smtp.<provider>.com` |
| **Mail Server Port** | `587` |
| **Security** | `TLS (STARTTLS)` |
| **SMTP Authentication** | Enabled |
| **Username** | `<provider_username>` |
| **Password** | `<api_token>` |

### 2. Alert Service Configuration
**Location**: `System` > `Alert Settings` > `Add Alert Service`

- **Alert Level**: `Info` (captures info, warnings, errors, and critical alerts)
- **Service Type**: Email
- **Recipient**: `<admin_email>@<yourdomain.com>`

---

## Alert Flow Architecture

```text
TrueNAS System Events
        ↓
Alert Service (Info Level+)
        ↓
SMTP Relay (smtp.<provider>.com:587)
        ↓
Managed SMTP Infrastructure
        ↓
Recipient Inbox (Instant Delivery)
```

---

## Alert Coverage
By setting the alert service to **Info** level, the following event categories trigger email notifications:

- **Hardware Events**: Disk failures, SMART errors, temperature warnings
- **Storage Events**: Pool state changes, scrub completion, space warnings
- **System Events**: Service failures, updates, configuration changes
- **VM/Container Events**: Resource constraints, startup/shutdown failures
- **Network Events**: Interface state changes, connectivity issues

---

## Testing & Validation

### Test Email from TrueNAS
In `System` > `General Settings` > `Email Options`:
1. Click **"Send Test Mail"**
2. Verify receipt at `<admin_email>@<yourdomain.com>`
3. Check the SMTP provider's dashboard for delivery confirmation

### Expected Test Email Subject
`TrueNAS Test Email` – confirms SMTP connectivity and authentication.

---

## Operational Notes

- **Delivery Visibility**: All TrueNAS alerts are visible in the provider's dashboard for audit purposes.
- **No Local Queue**: TrueNAS sends directly to the relay; failed deliveries are logged in `/var/log/mail.log` (or equivalent) on the TrueNAS system.
- **Rate Limiting**: Monitor provider usage limits (e.g., daily/monthly caps) to avoid hitting limits during high-alert scenarios (like a failing disk spamming alerts).
- **Alert Fatigue**: Info-level alerts capture everything. Consider creating separate services for `Warning` and `Critical` levels if volume becomes excessive.

---

## Troubleshooting

| Issue | Check |
| :--- | :--- |
| **Test email fails** | Verify SMTP credentials, port 587 accessibility, and TLS settings. |
| **Alerts not sending** | Confirm Alert Service is enabled and recipient email is correct. |
| **Emails delayed** | Check the provider's dashboard for queue status, rate limiting, or delivery failures. |
| **Authentication errors** | Regenerate the API token in the provider's dashboard and update the TrueNAS config. |
