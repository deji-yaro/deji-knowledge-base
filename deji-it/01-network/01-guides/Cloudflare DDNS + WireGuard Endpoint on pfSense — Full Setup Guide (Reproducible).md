

This is the complete, correct-order procedure for pointing a WireGuard endpoint at a Cloudflare-managed hostname via pfSense's built-in Dynamic DNS client — written from an actual setup, including the mistakes made and what fixed them, so this can be reproduced without hitting the same dead ends.

Assumes: pfSense already has a working WireGuard tunnel configured (see the separate WireGuard P2S guide), sitting behind an ISP router doing NAT (double-NAT), and a domain already managed in Cloudflare (`dejiyaro.com` in this example, hostname `beacon`).

---

## 1. Pick a hostname

Avoid names that self-narrate what the subdomain is for (`vpn.`, `wg.`, `remote.`, `admin.`) — these tell a casual observer exactly what they're looking at for no real security benefit, since a real attacker scans ports rather than reads DNS. Avoid random strings too — they cost you typing on mobile for no extra protection, since the thing actually protecting the tunnel is WireGuard's silent-drop behavior on invalid handshakes, not the hostname.

Land on something plain and easy to type: `beacon.dejiyaro.com` was the choice here.

---

## 2. Create the Cloudflare DNS record FIRST — before touching pfSense

**This is the step that was missed originally and cost the most troubleshooting time.** pfSense's Cloudflare DDNS client does not create a new record from scratch — it only updates an existing one. If the record doesn't exist yet, every update attempt fails with:

```
(Error) Zone or Host ID was not found, check the hostname.
```

even when authentication, permissions, and connectivity are all otherwise correct.

**Do this before creating the DDNS client in pfSense:**

1. Cloudflare dashboard → your domain → **DNS** → **Add record**
2. Type: `A`
3. Name: `beacon` (just the subdomain part, not the full FQDN)
4. IPv4 address: any placeholder value, e.g. `1.2.3.4` — pfSense will overwrite this on first successful update
5. **Proxy status: DNS only (grey cloud)** — not proxied. Cloudflare's proxy only terminates HTTP/HTTPS; it does not pass arbitrary UDP, so a proxied record silently breaks the WireGuard handshake entirely. Confirm this stays grey-cloud after every future edit too.
6. Save

---

## 3. Create a scoped Cloudflare API Token

Don't use the Global API Key — a scoped token limits damage if it's ever exposed.

1. Cloudflare dashboard → profile icon → **My Profile → API Tokens**
2. **Create Token → Create Custom Token**
3. Permissions — **add both of these rows** (both are required; DNS:Edit alone was tried initially and is not sufficient for how pfSense's client validates the zone):
    - `Zone` → `DNS` → `Edit`
    - `Zone` → `Zone` → `Read`
4. Zone Resources: `Include` → `Specific zone` → your domain
5. Continue to summary → **Create Token**
6. Copy the token immediately — Cloudflare shows it only once

---

## 4. Add a custom Check IP Service in pfSense

Needed because pfSense sits behind the ISP router — its own WAN interface address is a private IP, not the real public one, so pfSense needs to ask an external service what its actual public IP is.

1. `Services > Dynamic DNS > Check IP Services` tab → **Add**
2. Name: e.g. `ifconfig-co`
3. URL: `https://ifconfig.co`
4. **Enable this service** — must be checked, or it silently won't be usable at all
5. Save
6. **Disable the built-in "Default" Check IP Service entry** on this same tab. pfSense does not offer a per-client dropdown to pick a named service — it uses whichever entries are enabled here, so leaving Default enabled alongside a custom one caused ambiguity in testing. Only one should be enabled.

---

## 5. Create the Dynamic DNS client in pfSense

`Services > Dynamic DNS > Dynamic DNS Clients` → **Add**

| Field                | Value                                                                       | Notes                                                                                                                                                                               |
| -------------------- | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Disable              | **unchecked**                                                               | confirm this — an accidentally-checked disable box was one of the false leads chased during troubleshooting                                                                         |
| Service Type         | Cloudflare                                                                  |                                                                                                                                                                                     |
| Interface to monitor | WAN                                                                         |                                                                                                                                                                                     |
| Check IP Mode        | **Automatic (default)**                                                     | not "Always" — Automatic already detects a private interface IP and falls back to the Check IP service on its own; this was simplified to Automatic after "Always" added no benefit |
| Hostname             | `[HOSTNAME]`                                                                | subdomain only                                                                                                                                                                      |
| Domain name          | `[DOMAIN]`                                                                  | pfSense concatenates Hostname + Domain name into the FQDN — do not put the full FQDN in the Hostname field alone, or you'll get `[FQDN]`                                            |
| Username             | your Cloudflare Zone ID (found on the domain's Overview page in Cloudflare) | for token-based auth, this is Zone ID — not your account email; email is only for the legacy Global API Key method                                                                  |
| Password             | the API Token from Step 3                                                   |                                                                                                                                                                                     |
| Cloudflare Proxy     | leave unchecked                                                             | this is a separate pfSense-side option; proxy status is actually controlled on the Cloudflare DNS record itself (Step 2)                                                            |
| TTL                  | default                                                                     |                                                                                                                                                                                     |

Save.

---

## 6. Force an update and verify via the log — don't just trust the status icon

1. On the client list, click **Force Update**
2. `Status > System Logs > System > General` → filter for `dyndns` or `Cloudflare`
3. **Enable Verbose Logging** on the client first if nothing shows up — default logging can be too sparse to show anything

**What a successful log looks like:**

```
Response Header: HTTP/2 200
Response Data: {"result":[{...}],"success":true,...}
Dynamic DNS cloudflare ([DOMAIN]): _checkStatus() ending.
```

A `"result":[]` (empty array) with `"total_count":0`, followed by the Zone/Host ID error, means the record doesn't exist yet in Cloudflare — go back to Step 2.

---

## 7. Confirm externally

- In Cloudflare, check the `beacon` A record now shows your actual public IP, and proxy status is still grey-cloud (DNS only)
- From a device on **cellular data**, not home WiFi (home WiFi can hairpin back to your own router and give a misleading result either way), run:
    
    ```
    dig [DOMAIN]
    ```
    
    or `nslookup beacon.dejiyaro.com` — confirm it returns your public IP

---

## 8. Client WireGuard config — using the hostname

DDNS only keeps the hostname pointed at the right IP; it doesn't change how clients connect. Every client still needs both hostname and port together:

```ini
[Interface]
PrivateKey = <client's own private key>
Address = 10.0.0.2/32
DNS = 10.0.0.1

[Peer]
PublicKey = <pfSense tunnel public key>
PresharedKey = <only if set on the pfSense peer entry>
Endpoint = [DOMAIN]:51820
AllowedIPs = 10.0.0.0/24, 10.0.0.0/16
PersistentKeepalive = 25
```

Replace `51820` if a different Listen Port was used on the pfSense tunnel.

---

## Troubleshooting reference — issues actually hit, in the order they came up

|Symptom|Cause|Fix|
|---|---|---|
|Log shows: _"There was an error trying to determine the public IP for interface - wan"_|Built-in default Check IP service (`checkip.dyndns.org`) unreliable/unreachable, or no Check IP Service usable at all|Add a custom Check IP Service (Step 4) and confirm it's enabled|
|Custom Check IP Service added but not selectable/usable|Service's own **Enable** checkbox wasn't checked|Edit the service entry, check Enable, save|
|Custom Check IP Service still not being used even though enabled|Built-in Default service was still enabled alongside it, causing ambiguity|Disable Default, leave only the custom one enabled|
|Assumed there was a dropdown to pick which named Check IP Service to use per client|Incorrect assumption — no such dropdown exists; service selection is controlled entirely by which entries are Enabled on the Check IP Services tab|N/A — corrected understanding, not a setting to change|
|DDNS client shows "Disable this client" checked|Manual/accidental toggle|Uncheck, save|
|Log shows HTTP 200 from Cloudflare, response body has `"result":[]"` and `"total_count":0`, followed by _"Zone or Host ID was not found, check the hostname"_|**The actual root cause**: pfSense's Cloudflare DDNS client updates existing records only — it does not create new ones. No `A` record existed yet for `beacon`|Manually create the `A` record in Cloudflare first (Step 2), then Force Update again|
|Token had only `Zone:DNS:Edit` permission|Insufficient for how pfSense's client validates/looks up the zone|Add `Zone:Zone:Read` permission to the token as well|
|Confusion over Username field|Tooltip text covers two different Cloudflare auth methods in one field; email is for Global API Key, Zone ID is for Token auth|Use Zone ID when authenticating via API Token (as done here), not account email|

---

## Summary of root cause

Every other layer — token permissions, IP detection, firewall rules, DNS resolution — was either already correct or a secondary fix along the way. The actual blocker was that **no DNS record existed in Cloudflare for the DDNS client to update**, since pfSense's client only performs updates, not creation. Creating the placeholder `A` record resolved it immediately once done.