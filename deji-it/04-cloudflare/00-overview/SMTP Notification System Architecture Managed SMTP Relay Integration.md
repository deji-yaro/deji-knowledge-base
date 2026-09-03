## Objective
Establish a reliable, authenticated, and low-maintenance SMTP notification system for infrastructure alerts. Self-hosting an SMTP server introduces unnecessary maintenance overhead and deliverability risks. A managed SMTP relay ensures 24/7 availability, official domain alignment, and proper authentication.

## Service Selection: Managed Relay (e.g., Resend)
- **Tier**: Free tier available (e.g., 100 emails/day, 3,000 emails/month).
- **Setup Time**: ~30 minutes.
- **Rationale**: Eliminates the complexity of maintaining mail server reputation, IP blacklisting, and queue management while guaranteeing instant delivery and full audit visibility.

---

## DNS Authentication Requirements
To ensure emails bypass spam filters and are properly authenticated, the following records must be configured at the domain provider:

| Record Type | Purpose | Example / Note |
| :--- | :--- | :--- |
| **TXT** | Domain Ownership Verification | Provided by the SMTP provider during domain setup. |
| **MX** | Mail Exchange Routing | Directs mail flow for the domain. |
| **SPF** | Sender Policy Framework | Authorizes the provider's IPs to send on behalf of `<yourdomain.com>`. |

*(Note: DKIM is also highly recommended and typically provided by the provider during domain setup to further cryptographically sign outgoing messages.)*

---

## SMTP Connection Parameters
Configure your infrastructure monitoring/alerting tool with the following connection details:

```ini
SMTP Host       : smtp.<provider>.com
SMTP Port       : 587
Encryption      : STARTTLS
Username        : <provider_default_username>
Password        : <your_api_token>
```
*The API token is generated directly within the provider's dashboard.*

---

## Addressing & Routing Logic
The system provides flexibility in how alerts are labeled at the recipient level without requiring multiple authenticated domains.

- **Default Recipient**: `<admin_email>@<yourdomain.com>`
- **Base Sender Domain**: `notifications.<yourdomain.com>` (or provider default)
- **Dynamic Local-Part**: The prefix before the `@` symbol is fully mutable via the SMTP client configuration. 

**Examples of valid `From` addresses:**
- `alert@notifications.<yourdomain.com>` (Critical infrastructure alerts)
- `info@notifications.<yourdomain.com>` (General system notifications)
- `test@notifications.<yourdomain.com>` (Test or specific service alerts)

This allows for easy visual filtering and rule creation in the recipient's mailbox based on the sender alias.

---

## Operational Visibility & Monitoring
- **Delivery Speed**: Emails arrive instantly.
- **Audit Trail**: Every email sent is logged and easily visible in the provider's dashboard, providing immediate feedback on delivery status, bounces, or rejections without needing to parse local mail logs.