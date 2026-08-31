### Part 1: Why We Do This (The Mechanics)

Nextcloud has a strict security model. By default, it only trusts requests that arrive directly at its known, configured hostnames. When you put Cloudflare (or any reverse proxy) in front of it, three things break that model:

1. **Host Header Rewriting**: Cloudflare terminates the external HTTPS connection and forwards the request to your TrueNAS instance internally, usually over HTTP. Nextcloud sees an `HTTP` request coming from an internal IP, not the `HTTPS` request from `files.dejiyaro.com`.
2. **The Redirect Loop / Mixed Content**: Because Nextcloud thinks the request is HTTP, it generates post-login redirects and asset links (CSS/JS) using `http://`. Your browser blocks these on an `https://` page (Mixed Content Policy), or the session cookie fails to bind to the correct domain. This is exactly what caused your "login hangs until refresh" symptom.
3. **The Trust Boundary**: If the `Host` header doesn't perfectly match an entry in `trusted_domains`, Nextcloud outright rejects the request with a 400 Bad Request or silently drops the session.

**The Fix**: We explicitly tell Nextcloud: 
* *"I trust these specific domains and IPs."* (`trusted_domains`)
* *"Even though you are receiving this internally via HTTP, pretend the client connected directly to `https://files.dejiyaro.com`."* (`overwritehost`, `overwriteprotocol`)
* *"I trust this proxy to tell me the real client IP."* (`trusted_proxies`)

---

### Part 2: The Golden Rule of TrueNAS SCALE

**Do not manually edit `/mnt/.ix-apps/app_mounts/nextcloud/html/config/config.php` unless absolutely necessary.** 

As the file's own header warns, TrueNAS SCALE's automated app update processes can and will overwrite manual changes to this file, stripping out comments and resetting arrays. The **only** persistent, update-safe way to modify Nextcloud configuration is via the `occ` (OwnCloud Console) command-line tool, which writes changes to a merged configuration safely.

---

### Part 3: How to Apply the Configuration (The Safe Way)

Do this via the TrueNAS SCALE Apps interface to ensure you are executing commands inside the correct container environment.

1. In the TrueNAS SCALE Web UI, go to **Apps** > **Installed Applications**.
2. Click on your **Nextcloud** app.
3. Look for the **Shell** or **Console** button (usually in the top right or under a "Pod/Container" dropdown) and open it.
4. Once inside the container shell, run the following commands sequentially. (The `www-data` user is required for proper file permissions).

```bash
# 1. Force Nextcloud to always generate HTTPS links for the public domain
php occ config:system:set overwritehost --value="[DOMAIN-NAME]"
php occ config:system:set overwriteprotocol --value="https"
php occ config:system:set overwrite.cli.url --value="[HTTPS://DOMAIN-NAME]"

# 2. Define all valid entry points (Public, LAN IP, Local DNS, Loopback)
php occ config:system:set trusted_domains 0 --value="[DOMAIN-NAME]"
php occ config:system:set trusted_domains 1 --value="[TRUENAS-IP]"
php occ config:system:set trusted_domains 2 --value="127.0.0.1"
php occ config:system:set trusted_domains 3 --value="[TRUENAS-DOMAIN]"
php occ config:system:set trusted_domains 4 --value="localhost"
php occ config:system:set trusted_domains 5 --value="nextcloud"

# 3. Tell Nextcloud to trust the local proxy/tunnel
php occ config:system:set trusted_proxies 0 --value="127.0.0.1"

# 4. Fix the boolean typo from earlier
php occ config:system:set twofactor_enforced --value=false --type=boolean

# 5. Update the .htaccess file to enforce these rules at the web server level
php occ maintenance:update:htaccess
```

---

### Part 4: The Manual Fallback (Use Only If `occ` Fails)

If you cannot access the app shell, you can edit the file directly. **Warning:** You may need to re-apply this after a major TrueNAS Nextcloud app update.

1. Open the file: `sudo nano /mnt/.ix-apps/app_mounts/nextcloud/html/config/config.php`
2. **Delete everything** in the file.
3. Paste the following cleaned, merged configuration. Replace the database passwords/salts with your *original* values if they differ from the ones you provided earlier (I have preserved your exact credentials from your previous dump).

```php
<?php
$CONFIG = array (
  'htaccess.RewriteBase' => '/',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'apps_paths' => 
  array (
    0 => array ( 'path' => '/var/www/html/apps', 'url' => '/apps', 'writable' => false ),
    1 => array ( 'path' => '/var/www/html/custom_apps', 'url' => '/custom_apps', 'writable' => true ),
  ),
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => array (
    'host' => '[HOST]',
    'password' => '[PASSWORD]',
    'port' => 6379,
  ),
  'upgrade.disable-web' => true,
  'passwordsalt' => '[PASSWORD-SALT]',
  'secret' => '[SECRET]',
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'pgsql',
  'version' => '34.0.2.1',
  'overwrite.cli.url' => '[HTTPS://DOMAIN-NAME]',
  'dbname' => '[NAME]',
  'dbhost' => 'postgres:5432',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'dbuser' => '[USER]',
  'dbpassword' => '[PASSWORD]',
  'installed' => true,
  'instanceid' => '[ID]',
  'preview_imaginary_url' => 'http://imaginary:9000',
  'mail_from_address' => '[ADDRESS]',
  'mail_smtpmode' => 'smtp',
  'mail_sendmailmode' => 'smtp',
  'mail_domain' => '[DOMAIN]',
  'twofactor_enforced' => false,
  'twofactor_enforced_groups' => array (),
  'twofactor_enforced_excluded_groups' => array (),
  'loglevel' => 2,
  'maintenance' => false,
  'trusted_domains' => array (
    0 => '[DOMAIN]',
    1 => '[TRUENAS-IP]',
    2 => '127.0.0.1',
    3 => '[TRUENAS-DOMAIN]',
    4 => 'localhost',
    5 => 'nextcloud',
  ),
  'overwritehost' => '[DOMAIN]', 
  'overwriteprotocol' => 'https',
  'overwritewebroot' => '/',
  'trusted_proxies' => array (
    0 => '127.0.0.1',
  ),
);
```
4. Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).
5. Restart the Nextcloud app from the TrueNAS UI to ensure PHP-FPM and the web server pick up the new config cleanly.

### Final Validation
Clear your browser cache completely. Test logging in via:
1. `https://files.dejiyaro.com` (Should load instantly, no refresh needed).
2. `http://10.0.96.253` (Should redirect to HTTPS or load cleanly if you access it directly, without trusted domain errors).

If both work, your proxy chain is correctly configured.