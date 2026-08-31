# 🐧 Linux Command Cheat-Sheet
### Ubuntu · Debian · Alpine — Professional Reference

> **Legend**
> - `[all]` — Command is identical on Ubuntu, Debian, and Alpine
> - Where commands differ, each distro column is shown separately
> - Alpine uses `apk`, BusyBox utilities, and `openrc` instead of `systemd`

---

## 📦 1. Package Management

| Use Case                   | Ubuntu                       | Debian                              | Alpine                                    |
| -------------------------- | ---------------------------- | ----------------------------------- | ----------------------------------------- |
| Update package index       | `apt update`                 | `apt update`                        | `apk update`                              |
| Upgrade all packages       | `apt upgrade -y`             | `apt upgrade -y`                    | `apk upgrade`                             |
| Full dist upgrade          | `apt full-upgrade -y`        | `apt full-upgrade -y`               | `apk upgrade --available`                 |
| Install a package          | `apt install <pkg>`          | `apt install <pkg>`                 | `apk add <pkg>`                           |
| Remove a package           | `apt remove <pkg>`           | `apt remove <pkg>`                  | `apk del <pkg>`                           |
| Remove + purge config      | `apt purge <pkg>`            | `apt purge <pkg>`                   | `apk del --purge <pkg>`                   |
| Autoremove unused deps     | `apt autoremove -y`          | `apt autoremove -y`                 | `apk cache clean`                         |
| Search for a package       | `apt search <pkg>`           | `apt search <pkg>`                  | `apk search <pkg>`                        |
| Show package info          | `apt show <pkg>`             | `apt show <pkg>`                    | `apk info <pkg>`                          |
| List installed packages    | `dpkg -l`                    | `dpkg -l`                           | `apk list --installed`                    |
| List files in a package    | `dpkg -L <pkg>`              | `dpkg -L <pkg>`                     | `apk info -L <pkg>`                       |
| Find which pkg owns a file | `dpkg -S /path/to/file`      | `dpkg -S /path/to/file`             | `apk info --who-owns /path/to/file`       |
| Install local .deb / .apk  | `dpkg -i pkg.deb`            | `dpkg -i pkg.deb`                   | `apk add --allow-untrusted pkg.apk`       |
| Fix broken dependencies    | `apt --fix-broken install`   | `apt --fix-broken install`          | *(N/A — apk resolves deps automatically)* |
| Hold a package version     | `apt-mark hold <pkg>`        | `apt-mark hold <pkg>`               | `apk add <pkg>=<version>` then pin        |
| Add repository (PPA)       | `add-apt-repository ppa:x/y` | *(manual /etc/apt/sources.list.d/)* | `echo "URL" >> /etc/apk/repositories`     |
| Clean package cache        | `apt clean`                  | `apt clean`                         | `apk cache clean`                         |

---

## 📁 2. File & Directory Management

| Use Case                           | Command `[all]`                    |
| ---------------------------------- | ---------------------------------- |
| List files (detailed)              | `ls -lah`                          |
| List with hidden files             | `ls -la`                           |
| Tree view of directory             | `tree -L 2`                        |
| Change directory                   | `cd /path/to/dir`                  |
| Go to home directory               | `cd ~` or `cd`                     |
| Go up one level                    | `cd ..`                            |
| Print working directory            | `pwd`                              |
| Create a directory                 | `mkdir -p /path/to/dir`            |
| Create a file                      | `touch filename.txt`               |
| Copy file                          | `cp source dest`                   |
| Copy directory recursively         | `cp -r src/ dest/`                 |
| Move / rename                      | `mv source dest`                   |
| Remove file                        | `rm filename`                      |
| Remove directory recursively       | `rm -rf /path/to/dir`              |
| Remove empty directory             | `rmdir dirname`                    |
| Find files by name                 | `find / -name "*.log" 2>/dev/null` |
| Find files by size                 | `find . -size +100M`               |
| Find files modified in last N days | `find . -mtime -7`                 |
| Search content in files            | `grep -r "pattern" /path/`         |
| Search with line numbers           | `grep -rn "pattern" /path/`        |
| Case-insensitive grep              | `grep -ri "pattern" /path/`        |
| Show file contents                 | `cat filename`                     |
| Page through file                  | `less filename`                    |
| Show first N lines                 | `head -n 20 filename`              |
| Show last N lines                  | `tail -n 20 filename`              |
| Follow log in real time            | `tail -f /var/log/syslog`          |
| Count lines / words / chars        | `wc -l filename`                   |
| Compare two files                  | `diff file1 file2`                 |
| Create symlink                     | `ln -s /target /link`              |
| Show symlink target                | `readlink -f /link`                |
| Disk usage of directory            | `du -sh /path/`                    |
| Archive to tar.gz                  | `tar -czf archive.tar.gz /path/`   |
| Extract tar.gz                     | `tar -xzf archive.tar.gz`          |
| List contents of tar.gz            | `tar -tzf archive.tar.gz`          |
| Compress with zip                  | `zip -r archive.zip /path/`        |
| Extract zip                        | `unzip archive.zip`                |
| Secure delete                      | `shred -u filename`                |

---

## 👤 3. User & Permission Management

| Use Case                       | Ubuntu / Debian                     | Alpine                           |
| ------------------------------ | ----------------------------------- | -------------------------------- |
| Add a user                     | `adduser username`                  | `adduser -D username`            |
| Add user (low-level)           | `useradd -m -s /bin/bash username`  | `adduser -D -s /bin/sh username` |
| Delete a user                  | `deluser username`                  | `deluser username`               |
| Delete user + home dir         | `deluser --remove-home username`    | `deluser -r username`            |
| Change password                | `passwd username` `[all]`           |                                  |
| Lock a user account            | `usermod -L username`               | `passwd -l username`             |
| Unlock a user account          | `usermod -U username`               | `passwd -u username`             |
| Add user to group              | `usermod -aG groupname username`    | `adduser username groupname`     |
| Create a group                 | `groupadd groupname`                | `addgroup groupname`             |
| Delete a group                 | `groupdel groupname`                | `delgroup groupname`             |
| List groups for user           | `groups username` `[all]`           |                                  |
| Show current user              | `whoami` `[all]`                    |                                  |
| Switch user                    | `su - username` `[all]`             |                                  |
| Run command as root            | `sudo <command>` `[all]`            |                                  |
| Edit sudoers safely            | `visudo` `[all]`                    |                                  |
| Show user/group IDs            | `id username` `[all]`               |                                  |
| List all users                 | `cat /etc/passwd` `[all]`           |                                  |
| List all groups                | `cat /etc/group` `[all]`            |                                  |
| Change file owner              | `chown user:group file` `[all]`     |                                  |
| Change permissions (symbolic)  | `chmod u+x file` `[all]`            |                                  |
| Change permissions (octal)     | `chmod 755 file` `[all]`            |                                  |
| Change permissions recursively | `chmod -R 750 /dir` `[all]`         |                                  |
| Change ownership recursively   | `chown -R user:group /dir` `[all]`  |                                  |
| Set SUID bit                   | `chmod u+s file` `[all]`            |                                  |
| Set sticky bit                 | `chmod +t /dir` `[all]`             |                                  |
| Show file permissions          | `stat filename` or `ls -la` `[all]` |                                  |
| Default permission mask        | `umask` `[all]`                     |                                  |
| Set default umask              | `umask 022` `[all]`                 |                                  |

---

## 🌐 4. Networking

### 4.1 Interface & IP Management

| Use Case                  | Ubuntu / Debian                                   | Alpine                                 |
| ------------------------- | ------------------------------------------------- | -------------------------------------- |
| Show IP addresses         | `ip addr show` or `ip a` `[all]`                  |                                        |
| Show a specific interface | `ip addr show eth0` `[all]`                       |                                        |
| Show routing table        | `ip route show` `[all]`                           |                                        |
| Add a static route        | `ip route add 10.0.0.0/8 via 192.168.1.1` `[all]` |                                        |
| Delete a route            | `ip route del 10.0.0.0/8` `[all]`                 |                                        |
| Show network interfaces   | `ip link show` `[all]`                            |                                        |
| Bring interface up        | `ip link set eth0 up` `[all]`                     |                                        |
| Bring interface down      | `ip link set eth0 down` `[all]`                   |                                        |
| Assign IP to interface    | `ip addr add 192.168.1.10/24 dev eth0` `[all]`    |                                        |
| Remove IP from interface  | `ip addr del 192.168.1.10/24 dev eth0` `[all]`    |                                        |
| Show ARP table            | `ip neigh show` `[all]`                           |                                        |
| Flush ARP cache           | `ip neigh flush all` `[all]`                      |                                        |
| Show interface statistics | `ip -s link show eth0` `[all]`                    |                                        |
| Configure a static IP     | edit `/etc/netplan/*.yaml` → `netplan apply`      | edit `/etc/network/interfaces`         |
| Apply Netplan config      | `netplan apply`                                   | *(N/A — no netplan)*                   |
| Restart network service   | `systemctl restart networking`                    | `service networking restart`           |
| Set hostname              | `hostnamectl set-hostname name`                   | `hostname name` + edit `/etc/hostname` |
| Show hostname             | `hostname` `[all]`                                |                                        |
| Show FQDN                 | `hostname -f` `[all]`                             |                                        |

### 4.2 DNS

| Use Case                               | Ubuntu / Debian                                                          | Alpine                                |
| -------------------------------------- | ------------------------------------------------------------------------ | ------------------------------------- |
| Show current DNS servers               | `cat /etc/resolv.conf` `[all]`                                           |                                       |
| DNS lookup (simple)                    | `nslookup hostname` `[all]`                                              |                                       |
| Detailed DNS query                     | `dig hostname` `[all]`                                                   |                                       |
| Query specific record type             | `dig hostname MX` / `dig hostname AAAA` `[all]`                          |                                       |
| Reverse DNS lookup                     | `dig -x <IP>` `[all]`                                                    |                                       |
| Trace DNS delegation                   | `dig +trace hostname` `[all]`                                            |                                       |
| Query specific DNS server              | `dig @8.8.8.8 hostname` `[all]`                                          |                                       |
| Short answer only                      | `dig +short hostname` `[all]`                                            |                                       |
| **Flush DNS cache (systemd-resolved)** | **`resolvectl flush-caches`**                                            | *(N/A — no resolved)*                 |
| Flush DNS (older alias)                | `systemd-resolve --flush-caches`                                         | *(N/A)*                               |
| Show resolved DNS stats                | `resolvectl statistics`                                                  | *(N/A)*                               |
| Show resolved DNS status               | `resolvectl status`                                                      | *(N/A)*                               |
| Check which DNS is used                | `resolvectl query hostname`                                              | `nslookup hostname`                   |
| Set DNS server temporarily             | edit `/etc/resolv.conf` `[all]`                                          |                                       |
| Set DNS via systemd-resolved           | edit `/etc/systemd/resolved.conf` → `systemctl restart systemd-resolved` | *(N/A)*                               |
| Flush nscd cache                       | `nscd -i hosts` *(if nscd installed)*                                    | `nscd -i hosts` *(if nscd installed)* |

### 4.3 Diagnostics & Testing

| Use Case | Ubuntu / Debian | Alpine |
|---|---|---|
| Ping a host | `ping -c 4 hostname` `[all]` | |
| Ping with interval | `ping -i 0.2 -c 100 hostname` `[all]` | |
| Ping6 (IPv6) | `ping6 -c 4 hostname` `[all]` | |
| Trace route to host | `traceroute hostname` | `traceroute hostname` *(install: `apk add traceroute`)* |
| Trace route (ICMP) | `traceroute -I hostname` `[all]` | |
| MTR (live traceroute) | `mtr hostname` *(install: `apt install mtr`)* | `mtr hostname` *(install: `apk add mtr`)* |
| Test port connectivity (nc) | `nc -zv host 443` `[all]` | |
| Scan port range | `nc -zv host 20-25` `[all]` | |
| Test UDP port | `nc -zuv host 53` `[all]` | |
| Check if port is open (bash) | `timeout 3 bash -c 'cat < /dev/null > /dev/tcp/host/80'` `[all]` | |
| Simple port scan | `nmap -p 22,80,443 host` *(install: `apt install nmap`)* | `nmap -p 22,80,443 host` *(install: `apk add nmap`)* |
| OS + service detection | `nmap -A host` `[all]` *(install nmap)* | |
| Scan entire subnet | `nmap -sn 192.168.1.0/24` `[all]` *(install nmap)* | |
| Check path MTU | `tracepath hostname` `[all]` | |
| Test ICMP latency | `ping -c 20 hostname \| tail -1` `[all]` | |

### 4.4 Sockets & Open Ports

| Use Case | Command `[all]` |
|---|---|
| All listening TCP/UDP ports | `ss -tulnp` |
| All established connections | `ss -tp` |
| Summary of socket stats | `ss -s` |
| Find what's using a port | `ss -tulnp \| grep :80` |
| Find what's using a port (lsof) | `lsof -i :80` |
| All connections to/from an IP | `ss -tnp dst 1.2.3.4` |
| Old-style netstat (ports) | `netstat -tulnp` *(install net-tools)* |
| Old-style netstat (connections) | `netstat -antp` *(install net-tools)* |

### 4.5 HTTP & File Transfer

| Use Case | Command `[all]` |
|---|---|
| Download a file (wget) | `wget https://url/file` |
| Download quietly | `wget -q https://url/file` |
| Resume interrupted download | `wget -c https://url/file` |
| HTTP HEAD request | `curl -I https://example.com` |
| Follow redirects | `curl -L https://example.com` |
| Download to file (curl) | `curl -O https://url/file` |
| Save with custom filename | `curl -o myfile.zip https://url/file` |
| POST JSON data | `curl -X POST -H 'Content-Type: application/json' -d '{"k":"v"}' https://api` |
| Pass auth header | `curl -H 'Authorization: Bearer TOKEN' https://api` |
| Verbose HTTP debug | `curl -v https://example.com` |
| Show only status code | `curl -o /dev/null -s -w "%{http_code}" https://example.com` |
| Check TLS/cert details | `curl -vI https://example.com 2>&1 \| grep -A5 "SSL"` |
| Time a request | `curl -o /dev/null -s -w "Total: %{time_total}s\n" https://example.com` |
| Upload a file via POST | `curl -F "file=@localfile.txt" https://example.com/upload` |

### 4.6 SSH & Remote Access

| Use Case | Command `[all]` |
|---|---|
| SSH into a remote host | `ssh user@host` |
| SSH on custom port | `ssh -p 2222 user@host` |
| SSH with identity file | `ssh -i ~/.ssh/id_ed25519 user@host` |
| SSH with verbose debug | `ssh -v user@host` |
| Run remote command | `ssh user@host 'uptime && df -h'` |
| SSH tunnel (local forward) | `ssh -L 8080:localhost:80 user@host` |
| SSH tunnel (remote forward) | `ssh -R 9090:localhost:3000 user@host` |
| SOCKS proxy via SSH | `ssh -D 1080 user@host` |
| Keep SSH alive | `ssh -o ServerAliveInterval=60 user@host` |
| Copy files (scp) | `scp file user@host:/path/` |
| Copy directory (scp) | `scp -r dir/ user@host:/path/` |
| Sync via SSH (rsync) | `rsync -avz /src/ user@host:/dest/` |
| Rsync dry run | `rsync -avzn /src/ user@host:/dest/` |
| Generate SSH key pair | `ssh-keygen -t ed25519 -C "comment"` |
| Copy public key to server | `ssh-copy-id user@host` |
| Add key to agent | `ssh-add ~/.ssh/id_ed25519` |
| List keys in agent | `ssh-add -l` |
| Test SSH config | `ssh -T git@github.com` |

### 4.7 Bandwidth & Traffic Monitoring

| Use Case | Ubuntu / Debian | Alpine |
|---|---|---|
| Live per-interface bandwidth | `iftop` *(install: `apt install iftop`)* | `iftop` *(install: `apk add iftop`)* |
| Per-process network usage | `nethogs` *(install: `apt install nethogs`)* | `nethogs` *(install: `apk add nethogs`)* |
| Interface byte counters | `vnstat` *(install: `apt install vnstat`)* | `vnstat` *(install: `apk add vnstat`)* |
| Live traffic stats | `nload eth0` *(install: `apt install nload`)* | `nload eth0` *(install: `apk add nload`)* |
| Per-IP traffic stats | `iptraf-ng` *(install: `apt install iptraf-ng`)* | *(install: `apk add iptraf-ng`)* |
| Capture packets (tcpdump) | `tcpdump -i eth0 -nn` `[all]` | |
| Capture on port | `tcpdump -i eth0 port 443` `[all]` | |
| Capture and save to file | `tcpdump -i eth0 -w capture.pcap` `[all]` | |
| Read a pcap file | `tcpdump -r capture.pcap` `[all]` | |
| Capture verbose packets | `tcpdump -i eth0 -nn -vvv` `[all]` | |
| Show TX/RX bytes (quick) | `cat /proc/net/dev` `[all]` | |
| Watch interface counters | `watch -n1 ip -s link show eth0` `[all]` | |

### 4.8 Network Configuration Files

| Config | Ubuntu / Debian | Alpine |
|---|---|---|
| Static IP config | `/etc/netplan/*.yaml` | `/etc/network/interfaces` |
| DNS resolver config | `/etc/systemd/resolved.conf` | `/etc/resolv.conf` |
| Hosts file (local DNS) | `/etc/hosts` `[all]` | |
| NTP config | `/etc/systemd/timesyncd.conf` | `/etc/chrony/chrony.conf` |
| Network service name resolution | `/etc/nsswitch.conf` `[all]` | |
| SSH client config | `~/.ssh/config` `[all]` | |
| SSH server config | `/etc/ssh/sshd_config` `[all]` | |

---

## ⚙️ 5. Process & System Monitoring

| Use Case | Command `[all]` |
|---|---|
| Interactive process monitor | `top` |
| Enhanced process monitor | `htop` *(install if needed)* |
| List all processes | `ps aux` |
| List processes (tree view) | `ps auxf` |
| Find process by name | `pgrep -a nginx` |
| Show process PID | `pidof nginx` |
| Kill process by PID | `kill <PID>` |
| Force kill | `kill -9 <PID>` |
| Kill process by name | `pkill nginx` |
| Kill all instances by name | `killall nginx` |
| Send signal to process | `kill -SIGHUP <PID>` |
| Run in background | `command &` |
| List background jobs | `jobs` |
| Bring job to foreground | `fg %1` |
| Run command immune to hangup | `nohup command &` |
| Persistent session | `screen` or `tmux` |
| Show system uptime | `uptime` |
| Show CPU info | `lscpu` |
| Show RAM usage | `free -h` |
| Show memory in detail | `cat /proc/meminfo` |
| Show CPU usage (snapshot) | `mpstat` |
| Per-core CPU stats | `mpstat -P ALL 1` |
| Show disk I/O | `iostat -x 1` |
| Real-time resource usage | `vmstat 1` |
| Show load average | `cat /proc/loadavg` |
| List open files by process | `lsof -p <PID>` |
| List files on a device | `lsof /dev/sda1` |
| Who is logged in | `w` or `who` |
| Last logins | `last` |
| Failed login attempts | `lastb` |
| System information summary | `uname -a` |
| OS release info | `cat /etc/os-release` |
| Kernel version | `uname -r` |

---

## 💽 6. Storage & Disk Management

| Use Case                    | Ubuntu / Debian                                                                                    | Alpine |                             |
| --------------------------- | -------------------------------------------------------------------------------------------------- | ------ | --------------------------- |
| Show disk usage             | `df -h` `[all]`                                                                                    |        |                             |
| Show partition table        | `fdisk -l` `[all]`                                                                                 |        |                             |
| Interactive partition tool  | `fdisk /dev/sda` `[all]`                                                                           |        |                             |
| GPT partition tool          | `gdisk /dev/sda` `[all]`                                                                           |        |                             |
| Create ext4 filesystem      | `mkfs.ext4 /dev/sdb1` `[all]`                                                                      |        |                             |
| Create XFS filesystem       | `mkfs.xfs /dev/sdb1` `[all]`                                                                       |        |                             |
| Mount a filesystem          | `mount /dev/sdb1 /mnt/data` `[all]`                                                                |        |                             |
| Unmount a filesystem        | `umount /mnt/data` `[all]`                                                                         |        |                             |
| Show mounted filesystems    | `mount \| column -t` `[all]`                                                                       |        |                             |
| Persistent mounts           | edit `/etc/fstab` `[all]`                                                                          |        |                             |
| Reload fstab without reboot | `mount -a` `[all]`                                                                                 |        |                             |
| Check filesystem integrity  | `fsck /dev/sdb1` `[all]`                                                                           |        |                             |
| Show block devices          | `lsblk` `[all]`                                                                                    |        |                             |
| Show device UUIDs           | `blkid` `[all]`                                                                                    |        |                             |
| Show largest files          | `du -ah /path \| sort -rh \| head -20` `[all]`                                                     |        |                             |
| Show inode usage            | `df -i` `[all]`                                                                                    |        |                             |
| Create swap file            | `fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile` `[all]` |        |                             |
| Show swap usage             | `swapon --show` `[all]`                                                                            |        |                             |
| LVM — list volume groups    | `vgs`                                                                                              | `vgs`  | *(install: `apk add lvm2`)* |
| LVM — list logical volumes  | `lvs`                                                                                              | `lvs`  | *(install: `apk add lvm2`)* |
| LVM — extend logical volume | `lvextend -L +10G /dev/vg0/lv0 && resize2fs /dev/vg0/lv0`                                          | same   | same                        |
| Benchmark disk speed (read) | `hdparm -t /dev/sda` `[all]`                                                                       |        |                             |
| Benchmark with dd (write)   | `dd if=/dev/zero of=/tmp/test bs=1M count=1024 oflag=direct` `[all]`                               |        |                             |
| Monitor disk I/O live       | `iotop` `[all]` *(install if needed)*                                                              |        |                             |
| SMART disk health           | `smartctl -a /dev/sda` `[all]` *(install smartmontools)*                                           |        |                             |

---

## 🔧 7. Services & Init System

| Use Case | Ubuntu / Debian (systemd) | Alpine (OpenRC) |
|---|---|---|
| Start a service | `systemctl start nginx` | `rc-service nginx start` |
| Stop a service | `systemctl stop nginx` | `rc-service nginx stop` |
| Restart a service | `systemctl restart nginx` | `rc-service nginx restart` |
| Reload config (no restart) | `systemctl reload nginx` | `rc-service nginx reload` |
| Show service status | `systemctl status nginx` | `rc-service nginx status` |
| Enable at boot | `systemctl enable nginx` | `rc-update add nginx default` |
| Disable at boot | `systemctl disable nginx` | `rc-update del nginx default` |
| Enable + start immediately | `systemctl enable --now nginx` | `rc-update add nginx && rc-service nginx start` |
| List all services | `systemctl list-units --type=service` | `rc-status --all` |
| List failed services | `systemctl --failed` | `rc-status -C` |
| Show service logs | `journalctl -u nginx -f` | `tail -f /var/log/nginx/error.log` |
| Show logs since last boot | `journalctl -b` | *(check /var/log/)* |
| Show logs for time range | `journalctl --since "1 hour ago"` | *(N/A — no journald)* |
| Show kernel messages | `journalctl -k` | `dmesg` |
| Reload systemd daemon | `systemctl daemon-reload` | *(N/A)* |
| Mask a service | `systemctl mask nginx` | *(N/A)* |
| Create systemd unit file | `/etc/systemd/system/myapp.service` | `/etc/init.d/myapp` *(OpenRC script)* |
| Reboot system | `systemctl reboot` | `reboot` |
| Shutdown system | `systemctl poweroff` | `poweroff` |
| View default run target | `systemctl get-default` | `rc-status` |

---

## 🔒 8. Security & Firewall

| Use Case                               | Ubuntu                                                                                      | Debian                                          | Alpine                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------- | ----------------------------------------------- | ----------------------------------------------- |
| **UFW (Ubuntu) / nftables / iptables** |                                                                                             |                                                 |                                                 |
| Check firewall status                  | `ufw status verbose`                                                                        | `iptables -L -n -v`                             | `iptables -L -n -v`                             |
| Enable firewall                        | `ufw enable`                                                                                | *(enable iptables via rules)*                   | *(enable via /etc/iptables/*)*                  |
| Allow a port                           | `ufw allow 80/tcp`                                                                          | `iptables -A INPUT -p tcp --dport 80 -j ACCEPT` | `iptables -A INPUT -p tcp --dport 80 -j ACCEPT` |
| Block a port                           | `ufw deny 23/tcp`                                                                           | `iptables -A INPUT -p tcp --dport 23 -j DROP`   | `iptables -A INPUT -p tcp --dport 23 -j DROP`   |
| Allow from specific IP                 | `ufw allow from 192.168.1.0/24`                                                             | `iptables -A INPUT -s 192.168.1.0/24 -j ACCEPT` | same                                            |
| Delete a UFW rule                      | `ufw delete allow 80/tcp`                                                                   | `iptables -D INPUT -p tcp --dport 80 -j ACCEPT` | same                                            |
| Save iptables rules                    | *(UFW persists automatically)*                                                              | `iptables-save > /etc/iptables/rules.v4`        | `iptables-save > /etc/iptables/rules-save`      |
| Restore iptables rules                 | *(UFW automatic)*                                                                           | `iptables-restore < /etc/iptables/rules.v4`     | `iptables-restore < /etc/iptables/rules-save`   |
| **Fail2Ban**                           |                                                                                             |                                                 |                                                 |
| Install Fail2Ban                       | `apt install fail2ban`                                                                      | `apt install fail2ban`                          | `apk add fail2ban`                              |
| Check banned IPs                       | `fail2ban-client status sshd` `[all]`                                                       |                                                 |                                                 |
| Unban an IP                            | `fail2ban-client set sshd unbanip <IP>` `[all]`                                             |                                                 |                                                 |
| **SSL/TLS**                            |                                                                                             |                                                 |                                                 |
| Generate self-signed cert              | `openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes` `[all]` |                                                 |                                                 |
| Check cert expiry                      | `openssl x509 -enddate -noout -in cert.pem` `[all]`                                         |                                                 |                                                 |
| Check remote cert                      | `openssl s_client -connect host:443 </dev/null` `[all]`                                     |                                                 |                                                 |
| Install Certbot (Let's Encrypt)        | `apt install certbot`                                                                       | `apt install certbot`                           | `apk add certbot`                               |
| Issue cert (standalone)                | `certbot certonly --standalone -d example.com` `[all]`                                      |                                                 |                                                 |
| Renew certs                            | `certbot renew --dry-run` `[all]`                                                           |                                                 |                                                 |
| **SSH Hardening**                      |                                                                                             |                                                 |                                                 |
| Edit SSH config                        | `nano /etc/ssh/sshd_config` `[all]`                                                         |                                                 |                                                 |
| Disable root login                     | set `PermitRootLogin no` in sshd_config `[all]`                                             |                                                 |                                                 |
| Disable password auth                  | set `PasswordAuthentication no` in sshd_config `[all]`                                      |                                                 |                                                 |
| Restart SSH daemon                     | `systemctl restart ssh`                                                                     | `systemctl restart ssh`                         | `rc-service sshd restart`                       |
| **File Integrity & Auditing**          |                                                                                             |                                                 |                                                 |
| Find SUID files                        | `find / -perm -4000 -type f 2>/dev/null` `[all]`                                            |                                                 |                                                 |
| Find world-writable files              | `find / -perm -o+w -type f 2>/dev/null` `[all]`                                             |                                                 |                                                 |
| Check file hash (SHA256)               | `sha256sum filename` `[all]`                                                                |                                                 |                                                 |
| Audit user sudo commands               | `grep sudo /var/log/auth.log`                                                               | `grep sudo /var/log/auth.log`                   | `grep sudo /var/log/messages`                   |

---

## 🐳 9. Docker & Containers

| Use Case | Command `[all]` |
|---|---|
| **Images** | |
| Pull an image | `docker pull nginx:latest` |
| List local images | `docker images` |
| Build image from Dockerfile | `docker build -t myapp:1.0 .` |
| Build with no cache | `docker build --no-cache -t myapp:1.0 .` |
| Tag an image | `docker tag myapp:1.0 registry/myapp:1.0` |
| Push image to registry | `docker push registry/myapp:1.0` |
| Remove an image | `docker rmi image_id` |
| Remove dangling images | `docker image prune` |
| Remove all unused images | `docker image prune -a` |
| **Containers** | |
| Run a container | `docker run -d --name myapp -p 80:80 nginx` |
| Run interactively | `docker run -it ubuntu /bin/bash` |
| Run with volume mount | `docker run -v /host/path:/container/path nginx` |
| Run with env variables | `docker run -e ENV_VAR=value nginx` |
| List running containers | `docker ps` |
| List all containers | `docker ps -a` |
| Stop a container | `docker stop myapp` |
| Start a container | `docker start myapp` |
| Restart a container | `docker restart myapp` |
| Remove a container | `docker rm myapp` |
| Force remove (running) | `docker rm -f myapp` |
| Exec into running container | `docker exec -it myapp /bin/bash` |
| Run one-off command in container | `docker exec myapp cat /etc/nginx/nginx.conf` |
| View container logs | `docker logs myapp` |
| Follow container logs | `docker logs -f myapp` |
| Inspect container config | `docker inspect myapp` |
| Show container resource usage | `docker stats` |
| Copy file into container | `docker cp file.txt myapp:/path/` |
| Copy file out of container | `docker cp myapp:/path/file.txt .` |
| **Networks & Volumes** | |
| List networks | `docker network ls` |
| Create a network | `docker network create mynet` |
| Connect container to network | `docker network connect mynet myapp` |
| List volumes | `docker volume ls` |
| Create a volume | `docker volume create mydata` |
| Remove unused volumes | `docker volume prune` |
| **Docker Compose** | |
| Start services | `docker compose up -d` |
| Stop services | `docker compose down` |
| Rebuild and restart | `docker compose up -d --build` |
| View compose logs | `docker compose logs -f` |
| Scale a service | `docker compose up -d --scale web=3` |
| List compose services | `docker compose ps` |
| Run command in compose service | `docker compose exec web /bin/bash` |
| **System Cleanup** | |
| Full system prune | `docker system prune -a --volumes` |
| Show docker disk usage | `docker system df` |

---

## 📋 10. Logs & Debugging

| Use Case | Ubuntu / Debian | Alpine |
|---|---|---|
| **System Logs** | | |
| Follow all system logs | `journalctl -f` | `tail -f /var/log/messages` |
| Logs since last boot | `journalctl -b` | *(no journald — check /var/log/)* |
| Logs by priority (errors only) | `journalctl -p err` | `grep -i error /var/log/messages` |
| Kernel messages | `dmesg -T` | `dmesg -T` |
| Auth / login events | `cat /var/log/auth.log` | `cat /var/log/auth.log` |
| Syslog | `cat /var/log/syslog` | `cat /var/log/messages` |
| Boot log | `cat /var/log/boot.log` | `cat /var/log/boot-complete` |
| **Debugging Tools** | | |
| Trace system calls | `strace -p <PID>` `[all]` | |
| Trace library calls | `ltrace ./binary` `[all]` | |
| Show ELF binary dependencies | `ldd /usr/bin/nginx` `[all]` | |
| Disassemble binary | `objdump -d /usr/bin/binary` `[all]` | |
| Read ELF info | `readelf -h /usr/bin/binary` `[all]` | |
| Check exit code of last cmd | `echo $?` `[all]` | |
| Run with env debugging | `env VAR=value command` `[all]` | |
| Print all env variables | `printenv` `[all]` | |
| Check which binary is used | `which nginx` or `type nginx` `[all]` | |
| Show full path of command | `command -v nginx` `[all]` | |
| Tee stdout to file + screen | `command \| tee output.log` `[all]` | |
| Redirect stderr to stdout | `command 2>&1` `[all]` | |
| Redirect all output to file | `command > out.log 2>&1` `[all]` | |
| Append to log file | `command >> out.log 2>&1` `[all]` | |
| Run at specific time | `at 03:00 < script.sh` `[all]` | |
| Schedule with cron | `crontab -e` `[all]` | |
| List cron jobs | `crontab -l` `[all]` | |
| **Performance Debugging** | | |
| Profile CPU (perf) | `perf top` `[all]` *(install: apt install linux-perf)* | |
| Record and report | `perf record ./binary && perf report` `[all]` | |
| Slow commands (time) | `time command` `[all]` | |
| Memory leak check | `valgrind --leak-check=full ./binary` `[all]` | |
| Network packet capture | `tcpdump -i eth0 port 80 -w capture.pcap` `[all]` | |
| Read pcap file | `tcpdump -r capture.pcap` `[all]` | |
| Live packet inspection | `tcpdump -i eth0 -nn -vvv` `[all]` | |

---

## 🛠️ Bonus: Shell Productivity

| Use Case | Command `[all]` |
|---|---|
| Repeat last command as sudo | `sudo !!` |
| Run previous command | `!!` |
| Search command history | `Ctrl+R` then type |
| Show last 50 history entries | `history 50` |
| Run command from history | `!<number>` |
| Clear screen | `clear` or `Ctrl+L` |
| Cancel current command | `Ctrl+C` |
| Pause process (bg) | `Ctrl+Z` then `bg` |
| Set an alias | `alias ll='ls -lah'` |
| Persist alias | add to `~/.bashrc` or `~/.profile` |
| Export env variable | `export VAR=value` |
| Show env variable | `echo $VAR` |
| Unset variable | `unset VAR` |
| Execute script | `bash script.sh` or `./script.sh` |
| Make script executable | `chmod +x script.sh` |
| Check shell syntax | `bash -n script.sh` |
| Debug script | `bash -x script.sh` |
| Redirect stdin from file | `command < input.txt` |
| Pipe chain example | `cat file \| grep error \| sort \| uniq -c \| sort -rn` |
| Multiline command | use `\` at end of line |
| Brace expansion | `mkdir -p /var/{log,run,cache}/myapp` |
| Arithmetic | `echo $((2 ** 10))` |
| String length | `echo ${#VAR}` |
| Substring | `echo ${VAR:0:5}` |
| Default value | `echo ${VAR:-default}` |
| here-doc (inline input) | `cat <<EOF ... EOF` |

---

*Generated for Ubuntu 22.04+, Debian 11+, Alpine 3.18+ — April 2026*
