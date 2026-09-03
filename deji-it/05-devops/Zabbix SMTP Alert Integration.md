## Objective
Configure Zabbix to route infrastructure alerts through a managed SMTP relay. This ensures monitoring notifications are authenticated, reliably delivered, and properly routed to the correct administrators based on severity.

---

## Phase 1: Media Type Configuration (SMTP Relay)
Define the SMTP connection parameters so Zabbix knows *how* to send the emails.

**Navigation**: `Alerts` > `Media types` > `Email` (or create new)

| Parameter | Value |
| :--- | :--- |
| **Name** | `<media_type_name>` |
| **Type** | Email |
| **Email provider** | Generic SMTP |
| **SMTP server** | `smtp.<provider>.com` |
| **SMTP server port** | `587` |
| **Email** | `alert@<yourdomain.com>` |
| **SMTP helo** | `<sender_identifier>` |
| **Connection security** | `STARTTLS` |
| **SSL verify peer** | Enabled (Checked) |
| **SSL verify host** | Enabled (Checked) |
| **Authentication** | Username and password |
| **Username** | `<smtp_username>` |
| **Password** | `<smtp_password_or_api_token>` |
| **Message format** | HTML |
| **Enabled** | Checked |

---

## Phase 2: Action Routing (The Trigger)
Define *when* Zabbix sends an alert. By default, Zabbix uses the "Report problems to Zabbix administrators" action.

**Navigation**: `Alerts` > `Actions` > `Report problems to <user_group_name>`

1. Ensure the action is **Enabled**.
2. Under the **Operations** tab, verify the "Send to User groups" is set to **`<user_group_name>`** (e.g., *Zabbix administrators*).
3. *Optional but recommended*: Check the "Default message" or "Custom message" templates to ensure the HTML formatting renders correctly via the SMTP provider.

*Note: This action links the trigger event to the User Group. The actual email delivery is handled in Phase 3.*

---

## Phase 3: User & Group Assignment (The Recipient)
Define *who* receives the alerts and at what severity levels. Zabbix requires a two-step verification here: confirming group membership, then defining the user's specific media (email) preferences.

### Step 3.1: Verify Group Membership
**Navigation**: `Users` > `User groups` > `<user_group_name>`
- Review the **Users** tab within this group.
- Ensure the target user accounts (e.g., your admin account) are actually members of this group. If they aren't, the Action in Phase 2 will ignore them.

### Step 3.2: Configure User Media
**Navigation**: `Users` > `Users` > Click the target **Username** > `Media` tab

1. Click **Add** in the Media section.
2. **Type**: Select the media type created in Phase 1 (`<media_type_name>`).
3. **Send to**: Enter the destination email address (e.g., `<admin_email>@<yourdomain.com>`).
4. **When active**: `1-7,00:00-24:00` (for 24/7 alerts).
5. **Use if severity**: Check the boxes for the desired alert levels (e.g., `Warning`, `Average`, `High`, `Disaster`). *Uncheck "Not classified" and "Information" to reduce alert fatigue unless specifically needed.*
6. **Status**: Enabled.
7. Click **Add**, then **Update** on the user profile.

---

## Alert Flow Architecture

```text
Zabbix Trigger (e.g., CPU > 90%)
        ↓
Zabbix Action ("Report problems...")
        ↓
Target User Group ("<user_group_name>")
        ↓
User Media Profile (Severity check & Email address)
        ↓
Media Type (<provider> SMTP Relay)
        ↓
Recipient Inbox
```

---

## Testing & Validation

1. **Test the Media Type**: 
   - Go to `Alerts` > `Media types`.
   - Click **Test** on the `<media_type_name>` row.
   - Enter a test email address and send. Verify receipt and check the SMTP provider's dashboard.
2. **Test the Full Pipeline**:
   - Temporarily lower a trigger threshold on a test host (e.g., set a CPU trigger to 1%).
   - Wait for the trigger to fire.
   - Verify the email arrives.
   - Check `Monitoring` > `Problems` to confirm the event state, and `Reports` > `Action log` to confirm Zabbix successfully processed the email dispatch.

---

## Troubleshooting

| Issue                                      | Check                                                                                                                                                                        |
| :----------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Media test works, but no alerts**        | Check the Action configuration (Phase 2). Ensure the target host/item is actually linked to the trigger, and the trigger severity matches the User Media settings (Phase 3). |
| **"Action log" shows "Sent" but no email** | Check the SMTP provider's dashboard. If the provider received it but it didn't arrive, check the recipient's spam/junk folder or mail flow rules.                            |
| **"Action log" shows "Failed"**            | Check Zabbix server logs (`/var/log/zabbix/zabbix_server.log`) for SMTP connection timeouts or authentication rejections.                                                    |
| **Wrong email format**                     | Ensure "Message format" in the Media Type is set to HTML, and the Action message templates are using HTML tags.                                                              |
