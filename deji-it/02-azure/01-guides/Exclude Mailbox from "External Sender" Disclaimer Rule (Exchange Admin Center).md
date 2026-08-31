# Exclude Mailbox from "External Sender" Disclaimer Rule (Exchange Admin Center)

## Purpose
Stop the "CAUTION: THIS EMAIL IS FROM OUTSIDE OF THE COMPANY" disclaimer from appearing on emails sent to `[EMAIL]`.

---

## Prerequisites
- **Global Admin** or **Exchange Admin** role
- Access to Exchange Admin Center (EAC)

---

## Steps

### 1. Access Exchange Admin Center
1. Go to **[admin.exchange.microsoft.com](https://admin.exchange.microsoft.com)**
2. Sign in with your admin account

### 2. Navigate to Mail Flow Rules
1. In the left menu, go to **Mail flow** → **Rules**
2. Locate the rule that adds the disclaimer. It’s likely named something like:
   - *"External Sender Warning"*
   - *"Add disclaimer to external emails"*
   - *"Caution Banner"*
3. Click the rule name to select it

### 3. Edit the Rule
1. With the rule selected, click the **Edit** button (pencil icon) at the top
2. The rule configuration panel will open

### 4. Add Exception for Specific Recipient
1. Scroll down to the **Exceptions** section (usually at the bottom)
2. Click **+ Add exception**
3. Select **The recipient...** → **is this person**
4. In the search box, type: `[EMAIL]`
5. Select the mailbox from the results
6. Click **Add**
7. Click **Save** on the exception dialog
8. Click **Save** at the bottom of the rule editor

### 5. Verify the Exception
1. Back in the **Rules** list, click the rule again
2. Confirm under **Exceptions** you see:
   > *Except if the recipient is [EMAIL]*

---

## Important Notes

- **Propagation time**: Rule changes take **15–60 minutes** to apply
- This only affects **incoming** external emails to `[EMAIL]`
- Emails sent **from** `[EMAIL]` to others are unaffected
- If you have multiple disclaimer rules, ensure you’re editing the correct one

---

## Verification

1. Send a test email from an **external** address (e.g., Gmail) to `[EMAIL]`
2. Confirm the "CAUTION" banner **does not appear**
3. Send a test email to a **different** internal mailbox
4. Confirm the banner **still appears** for other users

---

## Rollback

To remove the exception:
1. Return to **Mail flow** → **Rules**
2. Edit the same rule
3. Under **Exceptions**, find `[EMAIL]`
4. Click the **X** next to it to remove
5. Click **Save**



