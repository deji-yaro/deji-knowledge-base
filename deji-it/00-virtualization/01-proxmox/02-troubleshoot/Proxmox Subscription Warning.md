### **Purpose**

Proxmox VE is open-source and free to use. However, the web interface displays a nag warning if the system isn't registered with a paid subscription. This does not affect functionality but can be annoying. The proper method is to use the no-subscription repository.

### **Proper Method: Using the No-Subscription Repo**

bash

```plain text
# Comment out the paid enterprise repository. '#' makes the line a comment, so it's ignored.sed -i 's|^deb|#deb|' /etc/apt/sources.list.d/pve-enterprise.list

# Add the free community (no-subscription) repository to the main sources list.echo "deb http://download.proxmox.com/debian/pve $(lsb_release -sc) pve-no-subscription" >> /etc/apt/sources.list

# Update the local APT package list to reflect the changes.apt update
```

- `**sed -i 's|^deb|#deb|' ...**`**:** The `sed` command edits the file in-place (`i`). It substitutes (`s|old|new|`) any line starting with (`^`) `deb` and replaces it with `#deb`.
- `**lsb_release -sc**`**:** This command returns your Proxmox version's codename (e.g., `bookworm`). Using this ensures you're adding the correct repo for your version.

### **Advanced Method: Disabling the Warning (Use with Caution)**

bash

```plain text
# This script is a cleaner alternative to manually editing the JS file.# It creates a systemd service to suppress the message.cat <<EOF > /etc/systemd/system/pve-nag.service
[Unit]
Description=Disable Proxmox VE Subscription Nag

[Service]
Type=oneshot
ExecStart=/usr/bin/sed -i 's/data.status !== "Active"/false/g' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
ExecStartPost=/usr/bin/systemctl restart pveproxy

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to see the new service, enable it to run on boot, and start it now.
systemctl daemon-reload
systemctl enable --now pve-nag.service
```

**Warning:** Editing Proxmox's JavaScript files directly (`proxmoxlib.js`) is brittle. Your changes will be **overwritten every time the **`**proxmox-widget-toolkit**`** package is updated**, requiring you to reapply the fix. The service method above will reapply it automatically on boot after an update.