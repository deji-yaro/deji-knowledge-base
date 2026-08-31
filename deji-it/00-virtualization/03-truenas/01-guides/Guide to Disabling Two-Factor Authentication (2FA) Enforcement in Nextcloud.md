
Two-factor authentication enforcement in Nextcloud requires all users (or specific groups) to set up 2FA before accessing their accounts. If enforcement is enabled but a user hasn't configured it, they may get locked out with a message like "Two-factor authentication is enforced but has not been configured on your account." Disabling enforcement allows logins without 2FA while you troubleshoot or reconfigure.

This guide covers the main methods to disable 2FA enforcement. It's based on Nextcloud's official documentation and community practices. Always back up your Nextcloud configuration and database before making changes to avoid data loss.[nextcloud+1](https://docs.nextcloud.com/server/stable/admin_manual/configuration_user/two_factor-auth.html)

## Prerequisites

- Administrative access to your Nextcloud server (e.g., SSH or container shell).
- If using Docker, access the container's bash shell (e.g., `docker exec -it your_container_name /bin/bash`).
- Nextcloud version 18 or later (earlier versions may have different commands).
- Run commands as the web server user (often `www-data`) if needed, using `sudo -u www-data`.

## Method 1: Disable via OCC Command (Recommended for CLI Access)

Nextcloud's OCC tool is the most straightforward way to manage settings from the command line. Navigate to your Nextcloud installation directory (typically `/var/www/html` in Docker setups).

1. **Access the Shell**: Enter your server's terminal or Docker container shell.
    
2. **Check Current Enforcement Status** (Optional):
    
    Run:
    
    `textphp occ twofactorauth:enforce`
    
    This shows if enforcement is on and for which groups.
    
3. **Disable Enforcement Globally**:
    
    Run:
    
    `textphp occ twofactorauth:enforce --off`
    
    This turns off 2FA enforcement for all users.[nextcloud](https://docs.nextcloud.com/server/27/admin_manual/configuration_user/two_factor-auth.html)
    
4. **Disable for Specific Groups (If Needed)**:
    
    If enforcement is group-based, use:
    
    `textphp occ twofactorauth:enforce --off --group group_name`
    
    Replace `group_name` with the actual group (e.g., `admin`).
    
5. **Verify Changes**:
    
    Attempt to log in via the web interface. If issues persist, restart your web server or container:
    
    `textdocker restart your_container_name`
    
    (Adjust for non-Docker setups, e.g., `systemctl restart apache2`.)
    

## Method 2: Edit the Configuration File (Manual Override)

If OCC commands fail or you prefer direct editing:

1. **Locate config.php**:
    
    Find it in your Nextcloud directory (e.g., `/var/www/html/config/config.php`).
    
2. **Edit the File**:
    
    Open it with a text editor (e.g., `nano config.php`) and look for:
    
    `php'twofactor_enforced' => true,`
    
    Change it to:
    
    `php'twofactor_enforced' => false,`
    
    If the line doesn't exist, add it under the `$CONFIG` array.[nextcloud](https://docs.nextcloud.com/server/stable/admin_manual/configuration_user/two_factor-auth.html)
    
3. **Save and Apply**:
    
    Save the file and clear any caches if needed:
    
    `textphp occ maintenance:repair`
    
    Restart your server or container.
    
4. **Group-Specific Edits** (Advanced):
    
    For groups, add or modify:
    
    `php'twofactor_enforced_groups' => array(),`
    
    To remove all enforced groups.[nextcloud](https://docs.nextcloud.com/server/27/admin_manual/configuration_user/two_factor-auth.html)
    

## Method 3: Disable via Web Interface (If You Can Log In)

If you have access to another admin account without 2FA issues:

1. Log in as an admin.
2. Go to **Settings** > **Security**.
3. Under "Two-Factor Authentication," uncheck "Enforce two-factor authentication."
4. For groups, manage via **Settings** > **Users** > **Group Management** and adjust 2FA settings per group.[nextcloud](https://docs.nextcloud.com/server/stable/admin_manual/configuration_user/two_factor-auth.html)

## Troubleshooting Common Issues

- **Command Not Found**: Ensure you're in the correct directory and that the Two-Factor Authentication app is installed/enabled. Update Nextcloud if using an outdated version.
    
- **Memory Limit Warning**: If you see PHP memory errors, increase the limit in `php.ini` (e.g., `memory_limit = 512M`) and restart.
    
- **Still Locked Out**: Check for individual user 2FA with:
    
    `textphp occ twofactorauth:state username`
    
    Disable specific providers:
    
    `textphp occ twofactorauth:disable username provider_id`
    
    (e.g., `totp` for authenticator apps).[nextcloud](https://help.nextcloud.com/t/disable-certain-2fa-provider-via-occ/72094)
    
- **Re-Enable Later**: To turn enforcement back on:
    
    `textphp occ twofactorauth:enforce --on`
    
    First, ensure all users have configured 2FA to avoid lockouts.
    

If these steps don't resolve your issue, consult Nextcloud's forums or logs (`data/nextcloud.log`) for errors. For Docker-specific setups, verify your image version and compose file.

1. [https://docs.nextcloud.com/server/stable/admin_manual/configuration_user/two_factor-auth.html](https://docs.nextcloud.com/server/stable/admin_manual/configuration_user/two_factor-auth.html)
2. [https://docs.nextcloud.com/server/27/admin_manual/configuration_user/two_factor-auth.html](https://docs.nextcloud.com/server/27/admin_manual/configuration_user/two_factor-auth.html)
3. [https://help.nextcloud.com/t/disable-certain-2fa-provider-via-occ/72094](https://help.nextcloud.com/t/disable-certain-2fa-provider-via-occ/72094)