# Bright Analytics – Business Central Connection Guide  
### Implementation & Troubleshooting

This guide covers the complete setup of the integration between **Bright Analytics** (consolidation/reporting platform) and **Microsoft Business Central** using Azure Active Directory (Microsoft Entra ID) OAuth2.  
It includes step‑by‑step implementation instructions and a comprehensive troubleshooting section for common issues.

---

## Part 1 – Implementation (Step by Step)

### Estimated Time
| Task | Time |
|------|------|
| Azure AD App Registration | 15–20 min |
| Business Central configuration | 10–15 min |
| Grant consent & final checks | 5–10 min |
| **Total** | **~30–45 min** |

---

### Step 1: Create an App Registration in Azure Portal

1. Go to [portal.azure.com](https://portal.azure.com) and sign in with a **Global Admin** or **Application Admin** account.
2. Search for and open **Azure Active Directory** (now called **Microsoft Entra ID**).
3. Click **App registrations** → **+ New registration**.
4. Fill in:
   - **Name**: `BrightAnalytics-BC-Connector` (or any clear name)
   - **Supported account types**: Leave default (“Accounts in this organizational directory only”)
   - **Redirect URI**: Leave blank for now (will add later if needed)
5. Click **Register**.

#### Record the following immediately:
- **Application (client) ID** – copy it
- **Directory (tenant) ID** – copy it

> 💡 These IDs are required by Bright Analytics.

---

### Step 2: Create a Client Secret

1. In your app registration, go to **Certificates & secrets**.
2. Click **+ New client secret**.
3. Add a description (e.g., `BrightAnalytics`) and choose an expiry (12 or 24 months recommended).
4. Click **Add**.
5. **Copy the secret value immediately** – it will not be shown again.

> ⚠️ Store the client secret securely. It will be sent to Bright Analytics.

---

### Step 3: Configure API Permissions

1. In your app registration, go to **API permissions**.
2. Click **+ Add a permission**.
3. Select **Dynamics 365 Business Central**.
4. Choose **Application permissions** (the integration runs as a background service without a signed‑in user).
5. In the list, select:
   - `Financials.ReadWrite.All` (or `API.ReadWrite.All` if specified by Bright Analytics)
6. Click **Add permissions**.
7. **Click “Grant admin consent for [your organization]”** – this step requires Global Admin rights.

> 🔐 Without granting admin consent, the permissions will not be active.

---

### Step 4: Add a Redirect URI (for Grant Consent to work)

When you click **Grant Consent** inside Business Central, Azure needs a registered reply URL.  
If missing, you will get error `AADSTS500113: No reply address is registered`.

1. In your app registration, go to **Authentication**.
2. Click **+ Add a platform** → **Web**.
3. In **Redirect URIs**, enter:

4. Click **Configure**.
5. (Optional) Also add `https://businesscentral.dynamics.com/0AuthLanding.htm` (some environments require the `0` version).

---
[https://businesscentral.dynamics.com/OAuthLanding.htm](https://businesscentral.dynamics.com/OAuthLanding.htm)
### Step 5: Find Your Business Central Environment URL

The API URL format required by Bright Analytics is:
[https://api.businesscentral.dynamics.com/v2.0/{tenant-id}/{environment-name}/](https://api.businesscentral.dynamics.com/v2.0/%7Btenant-id%7D/%7Benvironment-name%7D/)

- **Tenant ID** = the Directory (tenant) ID from Step 1.
- **Environment name** = usually `Production` or `Sandbox`.  
  You can find it in the UI URL when logged into BC:  
  `https://businesscentral.dynamics.com/Production/?noSignUpCheck=1`

**Example:**
[https://api.businesscentral.dynamics.com/v2.0/39aabbea-2938-4cf8-b94c-c78093a65c43/Production/](https://api.businesscentral.dynamics.com/v2.0/39aabbea-2938-4cf8-b94c-c78093a65c43/Production/)

> 📌 This URL does **not** open in a browser – it is an API endpoint. It will return an error when accessed directly, which is normal.

---

### Step 6: Register the App in Business Central

Now you need to add the Azure AD application inside Business Central.

#### 6.1 Switch to the correct company
- In BC, click the **Settings** icon (top right) → **My Settings**.
- Change **Company** from `CRONUS NL` (demo) to your actual company (e.g. `PLS Nordic`).
- Click **OK**.

#### 6.2 Open the Microsoft Entra Applications list
- Press **Alt+Q** and search for `Microsoft Entra Applications` (or `Azure Active Directory Applications`).
- Alternatively, use the direct page number:  
  `https://businesscentral.dynamics.com/Production/?page=9860` (list view)  
  or `https://businesscentral.dynamics.com/Production/?page=9861` (card view)

#### 6.3 Add a new application
- Click **+ New**.
- Fill in:
  - **Client ID** = the Application (client) ID from Step 1.
  - **Description** = `BrightAnalytics-BC-Connector`
  - **State** = `Enabled`
- In the **User Permission Sets** section at the bottom, click **New Line** and add:
  - `D365 BUS FULL ACCESS` (or `SUPER` if allowed)
- Click the **Grant Consent** button at the top.
- A Microsoft sign‑in popup appears – sign in with your admin account.
- You should see **“Consent was given successfully!”**

> ✅ **This final Grant Consent step is critical.** Without it, the app will appear disabled or missing, and Bright Analytics cannot connect.

---

### Step 7: Send Credentials to Bright Analytics

Compile the following information and send to Axelle (or your contact at Bright Analytics):

| Field | Example / Value |
|-------|----------------|
| Application (Client) ID | `ea7b18b9-a3f8-4984-be96-904c7435915f` |
| Directory (Tenant) ID | `39aabbea-2938-4cf8-b94c-c78093a65c43` |
| Client Secret Value | (the value you copied) |
| Business Central URL | `https://api.businesscentral.dynamics.com/v2.0/{tenant-id}/Production/` |
| Budget name / location | (if known – otherwise state that no budgets were found) |

Also attach two screenshots:
1. **Azure App Registration overview** – showing Application ID, Directory ID, and API permissions.
2. **Business Central Microsoft Entra Application card** – showing the Client ID, Description, State = Enabled, and the success message after Grant Consent.

> 🔒 For security, consider sending the client secret via a secure channel (password manager share, encrypted message) rather than plain email.

---

## Part 2 – Troubleshooting Guide

This section lists common errors encountered during the setup and how to resolve them.

### Error 1: “Request Data Invalid” when testing the URL in a browser

**Symptom:**  
You paste the API URL `https://api.businesscentral.dynamics.com/v2.0/.../Production/` into a browser and see a JSON error like `{"error":{"code":"RequestDataInvalid"...}}`.

**Explanation:**  
This is **normal**. The URL is an API endpoint, not a web page. It expects authenticated calls with client credentials. Bright Analytics will make those calls correctly.

**Solution:**  
No action needed. Provide the URL as-is to Bright Analytics.

---

### Error 2: Cannot find “Azure Active Directory Applications” in Business Central

**Possible causes & fixes:**

| Cause | Fix |
|-------|-----|
| Wrong company (e.g., CRONUS NL) | Go to **My Settings** → change Company to your real company (e.g., PLS Nordic). |
| Insufficient permissions | Ensure your BC user has **SUPER** or **D365 BUS FULL ACCESS** permission set. |
| Using old search term | Search for **Microsoft Entra Applications** (new name). |
| Page hidden | Use direct page numbers: `?page=9860` (list) or `?page=9861` (card). |

---

### Error 3: The app registration is visible in one company but missing in another

**Symptom:**  
You see the `BrightAnalytics-BC-Connector` entry when in Company A, but not in Company B.

**Explanation:**  
Azure AD app registrations in BC are **company‑specific**. If you created the app while in CRONUS NL, it will not appear in PLS Nordic.

**Solution:**  
1. Switch to the correct company (PLS Nordic).  
2. Re‑create the app entry using the same Client ID.  
3. Set State = Enabled, add permission set, and click **Grant Consent** again.

---

### Error 4: AADSTS500113 – No reply address registered

**Symptom:**  
When clicking **Grant Consent** in BC, you get an error popup:  
`AADSTS500113: No reply address is registered for the application.`

**Cause:**  
The Azure app registration is missing a Redirect URI.

**Fix (in Azure Portal):**  
1. Go to your app registration → **Authentication**.  
2. **+ Add a platform** → **Web**.  
3. Enter Redirect URI:  
   `https://businesscentral.dynamics.com/OAuthLanding.htm`  
4. (Optional) also add `https://businesscentral.dynamics.com/0AuthLanding.htm`.  
5. Click **Configure**.  
6. Return to BC and click **Grant Consent** again – it will now work.

---

### Error 5: Grant Consent button does nothing or is greyed out

**Possible causes:**

- You are not signed in as a **Global Admin** in the popup.  
- The Redirect URI is still missing (see Error 4).  
- The app entry’s **State** is `Disabled` – change it to `Enabled` before granting consent.

**Fix:**  
- Verify you are a Global Admin in Azure AD.  
- Complete Error 4 first.  
- Ensure the app card shows **State = Enabled**.

---

### Error 6: The app appears but Bright Analytics cannot connect (connection fails)

**Checklist:**

| Item | Action |
|------|--------|
| Client Secret expired | Go to Azure → Certificates & secrets → check expiry date. Renew if needed. |
| Client Secret copied incorrectly | Re‑copy the **Value** (not the Secret ID). |
| Tenant ID or Client ID has extra spaces | Re‑paste without leading/trailing spaces. |
| API permissions missing admin consent | Go to Azure → API permissions → ensure “Grant admin consent” shows a green checkmark. |
| BC environment name case‑sensitive | Use exactly `Production` (capital P), not `production`. |
| State = Disabled in BC | Open the app in BC and set State to Enabled. |
| No permission set assigned | Add `D365 BUS FULL ACCESS` in the User Permission Sets section. |
| Grant Consent not performed | Click **Grant Consent** again and complete the sign‑in. A success message must appear. |

---

### Error 7: “G/L Budgets” is empty or no budgets found

**Symptom:**  
You search for G/L Budgets (page 113) and see an empty list in every company.

**Explanation:**  
Budgets may not have been created or imported into Business Central yet. This does **not** block the integration – Bright Analytics can still connect, but budget data will be missing.

**Solution:**  
- Inform Bright Analytics that no G/L budgets exist currently.  
- Ask if budgets need to be created in BC or if they can be provided from another source.  
- If budgets exist elsewhere (Excel, legacy system), coordinate with your finance team to import them into BC.

---

### Error 8: After four weeks the connection is not working / app “disappeared”

**Typical reason:**  
The **Grant Consent** step was never completed successfully. The app entry existed in BC but was never activated.

**How to verify:**
1. Switch to the correct company (PLS Nordic).  
2. Open Microsoft Entra Applications (page 9861).  
3. Check if the app has:
   - State = Enabled
   - A user name under “User Name” (e.g., `BRIGHTANALYTICS-BC-CONNECTOR`)
   - A permission set assigned
   - A green “Consent given” indicator

**Fix:**  
If any of the above is missing, edit the app entry, set State = Enabled, add permission set, and click **Grant Consent** again.

---

## Final Checklist for a Working Connection

- [ ] Azure AD app registration exists with Client ID and Tenant ID.
- [ ] Client secret created and stored securely.
- [ ] API permissions set to **Application permissions** for Business Central, with `Financials.ReadWrite.All` and **admin consent granted**.
- [ ] Redirect URI `https://businesscentral.dynamics.com/OAuthLanding.htm` added in Azure.
- [ ] Business Central URL constructed correctly: `https://api.businesscentral.dynamics.com/v2.0/{tenant-id}/{environment}/`.
- [ ] In BC, switched to the correct company (not CRONUS NL).
- [ ] Microsoft Entra Applications entry created with Client ID, Description, State = Enabled.
- [ ] Permission set `D365 BUS FULL ACCESS` assigned.
- [ ] **Grant Consent** button clicked and success message received.
- [ ] Screenshot of the BC app card taken.
- [ ] All credentials + screenshot sent to Bright Analytics.
- [ ] Bright Analytics confirms they can connect.

---

> 📌 **Remember:** The integration runs as a background service. No user needs to be logged in. The client secret must be renewed before expiry – set a calendar reminder for 1 month before the expiry date.

If you still encounter issues, contact Bright Analytics support (ticket #85953) with the screenshots and error messages.