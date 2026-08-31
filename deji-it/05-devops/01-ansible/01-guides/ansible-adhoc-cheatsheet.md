# Ansible Ad-Hoc Commands — Complete Cheat Sheet

> Ad-hoc commands are one-liners executed directly from the terminal without writing a playbook.
> Syntax: `ansible <host/group> [options] -m <module> -a "<arguments>"`

---

## Table of Contents

1. [Command Structure & Flags](#1-command-structure--flags)
2. [Connectivity & Ping](#2-connectivity--ping)
3. [Package Management](#3-package-management)
4. [Service Management](#4-service-management)
5. [File & Directory Operations](#5-file--directory-operations)
6. [Copy & Fetch Files](#6-copy--fetch-files)
7. [User & Group Management](#7-user--group-management)
8. [Cron Jobs](#8-cron-jobs)
9. [System Information & Facts](#9-system-information--facts)
10. [Command & Shell Execution](#10-command--shell-execution)
11. [Networking](#11-networking)
12. [Firewall Management](#12-firewall-management)
13. [Disk & Filesystem](#13-disk--filesystem)
14. [Process Management](#14-process-management)
15. [Log Management](#15-log-management)
16. [Environment Variables](#16-environment-variables)
17. [Git Operations](#17-git-operations)
18. [Database Operations](#18-database-operations)
19. [Docker Operations](#19-docker-operations)
20. [Inventory Patterns & Targeting](#20-inventory-patterns--targeting)
21. [Output & Verbosity Control](#21-output--verbosity-control)
22. [Parallel Execution & Throttling](#22-parallel-execution--throttling)
23. [Vault & Secrets](#23-vault--secrets)
24. [Common Real-World One-Liners](#24-common-real-world-one-liners)

---

## 1. Command Structure & Flags

```bash
ansible <pattern> -i <inventory> -m <module> -a "<args>" [flags]
```

### Essential Flags

| Flag | Long Form | Description |
|------|-----------|-------------|
| `-i` | `--inventory` | Specify inventory file or host |
| `-m` | `--module-name` | Module to use (default: `command`) |
| `-a` | `--args` | Arguments to pass to the module |
| `-b` | `--become` | Escalate to sudo/root |
| `-u` | `--user` | SSH user to connect as |
| `-k` | `--ask-pass` | Prompt for SSH password |
| `-K` | `--ask-become-pass` | Prompt for sudo password |
| `-f` | `--forks` | Number of parallel processes (default: 5) |
| `-v` | `--verbose` | Verbose output (`-vvv` for more) |
| `-C` | `--check` | Dry run — show what would change |
| `-D` | `--diff` | Show file diffs when changed |
| `--limit` | `--limit` | Further limit hosts from pattern |
| `--timeout` | `--timeout` | SSH connection timeout in seconds |
| `--private-key` | `--private-key` | Path to SSH private key |

### Quick Examples

```bash
# Run against all hosts in inventory
ansible all -m ping

# Run against specific group with custom inventory file
ansible webservers -i /etc/ansible/production -m ping

# Run as different user
ansible db -u deploy -b -m ping

# Dry run to see what would change
ansible all -b -m apt -a "name=nginx state=latest" -C

# Show diff of file changes
ansible all -b -m copy -a "src=nginx.conf dest=/etc/nginx/nginx.conf" -D
```

---

## 2. Connectivity & Ping

```bash
# Ping all hosts (tests SSH + Python, not ICMP)
ansible all -m ping

# Ping a specific group
ansible webservers -m ping

# Ping a single host
ansible web01 -m ping

# Ping with custom SSH user and key
ansible all -m ping -u ubuntu --private-key ~/.ssh/mykey.pem

# Ping with password auth
ansible all -m ping -u admin -k

# Test connectivity with verbose output
ansible all -m ping -vvv

# Test just one host from a group
ansible webservers --limit web01 -m ping

# Gather minimal facts to test connectivity
ansible all -m setup -a "gather_subset=min"
```

---

## 3. Package Management

### APT (Debian / Ubuntu)

```bash
# Install a package
ansible all -b -m apt -a "name=nginx state=present"

# Install multiple packages
ansible all -b -m apt -a "name=nginx,curl,vim state=present"

# Install latest version
ansible all -b -m apt -a "name=nginx state=latest"

# Remove a package
ansible all -b -m apt -a "name=nginx state=absent"

# Remove package and its config files (purge)
ansible all -b -m apt -a "name=nginx state=absent purge=yes"

# Update apt cache only
ansible all -b -m apt -a "update_cache=yes"

# Update cache and install
ansible all -b -m apt -a "name=nginx state=present update_cache=yes"

# Upgrade all packages
ansible all -b -m apt -a "upgrade=dist"

# Install specific version
ansible all -b -m apt -a "name=nginx=1.18.0-0ubuntu1 state=present"
```

### DNF / YUM (RHEL / CentOS / Fedora)

```bash
# Install a package
ansible all -b -m dnf -a "name=nginx state=present"

# Install multiple packages
ansible all -b -m dnf -a "name=nginx,curl,vim state=present"

# Install latest
ansible all -b -m dnf -a "name=nginx state=latest"

# Remove a package
ansible all -b -m dnf -a "name=nginx state=absent"

# Update all packages
ansible all -b -m dnf -a "name=* state=latest"

# Install from specific repo
ansible all -b -m dnf -a "name=nginx enablerepo=epel state=present"

# Install a local RPM
ansible all -b -m dnf -a "name=/tmp/myrpm.rpm state=present"
```

### Generic Package Module (distro-agnostic)

```bash
# Works on both apt and dnf systems
ansible all -b -m package -a "name=curl state=present"
ansible all -b -m package -a "name=htop state=latest"
ansible all -b -m package -a "name=telnet state=absent"
```

---

## 4. Service Management

```bash
# Start a service
ansible all -b -m service -a "name=nginx state=started"

# Stop a service
ansible all -b -m service -a "name=nginx state=stopped"

# Restart a service
ansible all -b -m service -a "name=nginx state=restarted"

# Reload a service (graceful, no downtime)
ansible all -b -m service -a "name=nginx state=reloaded"

# Enable service to start on boot
ansible all -b -m service -a "name=nginx enabled=yes"

# Disable service from starting on boot
ansible all -b -m service -a "name=nginx enabled=no"

# Start and enable in one command
ansible all -b -m service -a "name=nginx state=started enabled=yes"

# Check service status (using systemd module)
ansible all -b -m systemd -a "name=nginx"

# Reload systemd daemon (after unit file changes)
ansible all -b -m systemd -a "daemon_reload=yes"

# Restart and enable with systemd module
ansible all -b -m systemd -a "name=nginx state=restarted enabled=yes daemon_reload=yes"
```

---

## 5. File & Directory Operations

```bash
# Create a directory
ansible all -b -m file -a "path=/opt/myapp state=directory"

# Create directory with specific permissions and owner
ansible all -b -m file -a "path=/opt/myapp state=directory owner=www-data group=www-data mode=0755"

# Create an empty file
ansible all -b -m file -a "path=/tmp/testfile state=touch"

# Delete a file
ansible all -b -m file -a "path=/tmp/testfile state=absent"

# Delete a directory recursively
ansible all -b -m file -a "path=/opt/oldapp state=absent"

# Change file permissions
ansible all -b -m file -a "path=/etc/myapp.conf mode=0640"

# Change file owner and group
ansible all -b -m file -a "path=/var/www/html owner=www-data group=www-data"

# Create a symlink
ansible all -b -m file -a "src=/opt/myapp/current dest=/var/www/html state=link"

# Remove a symlink
ansible all -b -m file -a "path=/var/www/html state=absent"

# Set file attributes recursively on a directory
ansible all -b -m file -a "path=/var/log/myapp state=directory recurse=yes owner=syslog mode=0755"
```

---

## 6. Copy & Fetch Files

### Copy (control machine → remote hosts)

```bash
# Copy a file to remote hosts
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts"

# Copy with permissions and owner
ansible all -b -m copy -a "src=nginx.conf dest=/etc/nginx/nginx.conf owner=root mode=0644"

# Copy and backup existing file
ansible all -b -m copy -a "src=nginx.conf dest=/etc/nginx/nginx.conf backup=yes"

# Copy inline content to a file (no src file needed)
ansible all -b -m copy -a "content='Hello World\n' dest=/tmp/hello.txt"

# Copy SSL certificate to all web servers
ansible webservers -b -m copy -a "src=/certs/wildcard.crt dest=/etc/ssl/certs/wildcard.crt mode=0644"

# Copy SSH authorized_keys
ansible all -b -m copy -a "src=authorized_keys dest=/home/deploy/.ssh/authorized_keys owner=deploy mode=0600"
```

### Fetch (remote hosts → control machine)

```bash
# Fetch a file from a remote host to control machine
ansible all -m fetch -a "src=/var/log/nginx/error.log dest=/tmp/logs/"

# Fetch and flatten (don't create host subdirectories)
ansible all -m fetch -a "src=/etc/hostname dest=/tmp/hostnames/ flat=yes"

# Fetch a config file from one server
ansible web01 -m fetch -a "src=/etc/nginx/nginx.conf dest=/tmp/nginx.conf flat=yes"
```

---

## 7. User & Group Management

```bash
# Create a user
ansible all -b -m user -a "name=john state=present"

# Create user with home directory, shell, and comment
ansible all -b -m user -a "name=john comment='John Doe' shell=/bin/bash home=/home/john state=present"

# Create system user (no home, no login)
ansible all -b -m user -a "name=myapp system=yes shell=/sbin/nologin state=present"

# Add user to supplementary groups
ansible all -b -m user -a "name=john groups=sudo,docker append=yes"

# Set user password (hashed — use python3 -c 'import crypt; print(crypt.crypt("pass"))')
ansible all -b -m user -a "name=john password='$6$rounds=656000$hash...'"

# Lock a user account
ansible all -b -m user -a "name=john password_lock=yes"

# Delete a user
ansible all -b -m user -a "name=john state=absent"

# Delete user and remove home directory
ansible all -b -m user -a "name=john state=absent remove=yes"

# Create a group
ansible all -b -m group -a "name=developers state=present"

# Create group with specific GID
ansible all -b -m group -a "name=developers gid=1500 state=present"

# Delete a group
ansible all -b -m group -a "name=developers state=absent"

# Add SSH authorized key for a user
ansible all -b -m authorized_key -a "user=john key='ssh-rsa AAAA...' state=present"

# Remove SSH authorized key
ansible all -b -m authorized_key -a "user=john key='ssh-rsa AAAA...' state=absent"
```

---

## 8. Cron Jobs

```bash
# Add a cron job (runs at midnight daily)
ansible all -b -m cron -a "name='daily backup' hour=0 minute=0 job='/opt/backup.sh'"

# Add cron job with specific schedule
ansible all -b -m cron -a "name='cleanup logs' minute=30 hour=2 weekday=0 job='/usr/bin/find /var/log -mtime +30 -delete'"

# Add cron job for specific user
ansible all -b -m cron -a "name='my task' user=deploy minute=0 hour=6 job='/home/deploy/task.sh'"

# Remove a cron job by name
ansible all -b -m cron -a "name='daily backup' state=absent"

# Add a cron environment variable
ansible all -b -m cron -a "name=MAILTO env=yes value=admin@example.com"

# Add @reboot cron job
ansible all -b -m cron -a "name='start app' special_time=reboot job='/opt/start.sh'"

# Add hourly cron job
ansible all -b -m cron -a "name='hourly check' special_time=hourly job='/opt/check.sh'"
```

---

## 9. System Information & Facts

```bash
# Gather all facts from all hosts
ansible all -m setup

# Gather facts and filter by keyword
ansible all -m setup -a "filter=ansible_distribution*"

# Get OS/distro info
ansible all -m setup -a "filter=ansible_os_family"

# Get memory info
ansible all -m setup -a "filter=ansible_memtotal_mb"

# Get CPU info
ansible all -m setup -a "filter=ansible_processor*"

# Get IP address info
ansible all -m setup -a "filter=ansible_default_ipv4"

# Get all network interfaces
ansible all -m setup -a "filter=ansible_interfaces"

# Get disk/mount info
ansible all -m setup -a "filter=ansible_mounts"

# Get hostname info
ansible all -m setup -a "filter=ansible_hostname"

# Get kernel version
ansible all -m setup -a "filter=ansible_kernel"

# Get uptime/date info
ansible all -m setup -a "filter=ansible_date_time"

# Get environment variables
ansible all -m setup -a "filter=ansible_env"

# Minimal fact gathering (faster)
ansible all -m setup -a "gather_subset=min"

# Skip facts entirely and run raw command for resource check
ansible all -m command -a "free -h"
ansible all -m command -a "df -h"
ansible all -m command -a "uptime"
ansible all -m command -a "nproc"
```

---

## 10. Command & Shell Execution

### command module (safe, no shell features)

```bash
# Run a basic command
ansible all -m command -a "uptime"

# Run command and change directory first
ansible all -m command -a "chdir=/opt/myapp ./start.sh"

# Run command only if a file does not exist
ansible all -m command -a "creates=/tmp/done.txt touch /tmp/done.txt"

# Run command only if a file exists
ansible all -m command -a "removes=/tmp/done.txt rm /tmp/done.txt"
```

### shell module (supports pipes, redirects, variables)

```bash
# Run shell command with pipe
ansible all -m shell -a "ps aux | grep nginx"

# Use shell variables
ansible all -m shell -a "echo $HOSTNAME"

# Run command with redirect
ansible all -m shell -a "echo 'test' > /tmp/test.txt"

# Run multiple commands
ansible all -m shell -a "cd /opt && ls -la"

# Get disk usage for a specific path
ansible all -m shell -a "du -sh /var/log/*"

# Check who is logged in
ansible all -m shell -a "who"

# Check listening ports
ansible all -b -m shell -a "ss -tlnp"

# Tail a log file
ansible all -b -m shell -a "tail -n 50 /var/log/syslog"

# Check a process
ansible all -m shell -a "pgrep -a nginx"
```

### raw module (no Python required — useful for bootstrapping)

```bash
# Run raw SSH command (no Python needed on target)
ansible all -m raw -a "uptime"

# Install Python on a host that doesn't have it yet
ansible all -b -m raw -a "apt-get install -y python3"
```

---

## 11. Networking

```bash
# Test connectivity to a host/port (wait_for module)
ansible all -m wait_for -a "host=db01 port=3306 timeout=10"

# Wait for SSH port to come up (useful after reboot)
ansible all -m wait_for -a "port=22 timeout=60"

# Get network interface facts
ansible all -m setup -a "filter=ansible_interfaces"

# Get default gateway
ansible all -m setup -a "filter=ansible_default_ipv4"

# Check if a port is listening
ansible all -b -m shell -a "ss -tlnp | grep 80"

# Resolve DNS from remote host
ansible all -m shell -a "dig google.com +short"

# Test HTTP response
ansible all -m uri -a "url=http://localhost return_content=yes"

# Test HTTPS endpoint
ansible all -m uri -a "url=https://example.com status_code=200"

# Flush DNS cache
ansible all -b -m shell -a "systemctl restart systemd-resolved"

# Show routing table
ansible all -b -m shell -a "ip route show"

# Show ARP table
ansible all -b -m shell -a "arp -n"
```

---

## 12. Firewall Management

### UFW (Ubuntu/Debian)

```bash
# Enable UFW
ansible all -b -m ufw -a "state=enabled"

# Allow a port
ansible all -b -m ufw -a "rule=allow port=80 proto=tcp"

# Allow port 443
ansible all -b -m ufw -a "rule=allow port=443 proto=tcp"

# Allow SSH (important — do this before enabling)
ansible all -b -m ufw -a "rule=allow port=22 proto=tcp"

# Deny a port
ansible all -b -m ufw -a "rule=deny port=23 proto=tcp"

# Allow from specific IP
ansible all -b -m ufw -a "rule=allow src=192.168.1.100 port=22"

# Delete a rule
ansible all -b -m ufw -a "rule=allow port=80 proto=tcp delete=yes"

# Reset UFW (removes all rules)
ansible all -b -m ufw -a "state=reset"
```

### Firewalld (RHEL/CentOS)

```bash
# Enable and start firewalld
ansible all -b -m service -a "name=firewalld state=started enabled=yes"

# Allow HTTP service permanently
ansible all -b -m firewalld -a "service=http permanent=yes state=enabled"

# Allow HTTPS service
ansible all -b -m firewalld -a "service=https permanent=yes state=enabled"

# Allow specific port
ansible all -b -m firewalld -a "port=8080/tcp permanent=yes state=enabled"

# Remove a service
ansible all -b -m firewalld -a "service=telnet permanent=yes state=disabled"

# Reload firewalld rules
ansible all -b -m shell -a "firewall-cmd --reload"
```

---

## 13. Disk & Filesystem

```bash
# Check disk usage on all hosts
ansible all -m shell -a "df -h"

# Check disk usage for specific path
ansible all -m shell -a "du -sh /var/log"

# Check inode usage
ansible all -m shell -a "df -i"

# Check disk I/O stats
ansible all -b -m shell -a "iostat -x 1 3"

# List block devices
ansible all -b -m shell -a "lsblk"

# Create a filesystem on a device
ansible all -b -m filesystem -a "fstype=ext4 dev=/dev/sdb"

# Mount a filesystem
ansible all -b -m mount -a "path=/mnt/data src=/dev/sdb fstype=ext4 state=mounted"

# Unmount a filesystem
ansible all -b -m mount -a "path=/mnt/data state=unmounted"

# Permanently unmount (removes from /etc/fstab)
ansible all -b -m mount -a "path=/mnt/data state=absent"

# Check /etc/fstab entries
ansible all -m shell -a "cat /etc/fstab"

# Check for large files
ansible all -b -m shell -a "find /var -size +100M -exec ls -lh {} \\;"
```

---

## 14. Process Management

```bash
# List all running processes
ansible all -m shell -a "ps aux"

# Find a specific process
ansible all -m shell -a "pgrep -a nginx"

# Kill a process by name
ansible all -b -m shell -a "pkill nginx"

# Kill a process by PID
ansible all -b -m shell -a "kill -9 1234"

# Check load average
ansible all -m shell -a "cat /proc/loadavg"

# Check running services (systemd)
ansible all -b -m shell -a "systemctl list-units --type=service --state=running"

# Check failed services
ansible all -b -m shell -a "systemctl --failed"

# Get system uptime
ansible all -m shell -a "uptime -p"
```

---

## 15. Log Management

```bash
# Tail syslog
ansible all -b -m shell -a "tail -n 100 /var/log/syslog"

# Tail auth log (failed logins, sudo usage)
ansible all -b -m shell -a "tail -n 50 /var/log/auth.log"

# Tail nginx access log
ansible webservers -b -m shell -a "tail -n 100 /var/log/nginx/access.log"

# Tail nginx error log
ansible webservers -b -m shell -a "tail -n 100 /var/log/nginx/error.log"

# Search logs for errors
ansible all -b -m shell -a "grep -i error /var/log/syslog | tail -n 50"

# Check journal logs (systemd)
ansible all -b -m shell -a "journalctl -n 100 --no-pager"

# Check journal for specific service
ansible all -b -m shell -a "journalctl -u nginx -n 50 --no-pager"

# Check journal since last boot
ansible all -b -m shell -a "journalctl -b --no-pager | tail -n 100"

# Rotate logs manually
ansible all -b -m shell -a "logrotate -f /etc/logrotate.conf"

# Clear journal logs older than 7 days
ansible all -b -m shell -a "journalctl --vacuum-time=7d"

# Check disk space used by journal
ansible all -b -m shell -a "journalctl --disk-usage"
```

---

## 16. Environment Variables

```bash
# Print all environment variables on remote hosts
ansible all -m shell -a "env"

# Print a specific environment variable
ansible all -m shell -a "echo $PATH"

# Set environment variable for a command
ansible all -m shell -a "MY_VAR=hello printenv MY_VAR"

# Add environment variable to /etc/environment
ansible all -b -m lineinfile -a "path=/etc/environment line='MY_VAR=myvalue' state=present"

# Read /etc/environment
ansible all -m shell -a "cat /etc/environment"
```

---

## 17. Git Operations

```bash
# Clone a repository
ansible all -m git -a "repo=https://github.com/user/repo.git dest=/opt/myapp"

# Clone a specific branch
ansible all -m git -a "repo=https://github.com/user/repo.git dest=/opt/myapp version=main"

# Clone a specific tag
ansible all -m git -a "repo=https://github.com/user/repo.git dest=/opt/myapp version=v1.2.0"

# Update an existing repo (pull latest)
ansible all -m git -a "repo=https://github.com/user/repo.git dest=/opt/myapp update=yes"

# Clone with SSH key
ansible all -m git -a "repo=git@github.com:user/repo.git dest=/opt/myapp key_file=/home/deploy/.ssh/id_rsa accept_hostkey=yes"

# Force checkout (discard local changes)
ansible all -m git -a "repo=https://github.com/user/repo.git dest=/opt/myapp force=yes"
```

---

## 18. Database Operations

### MariaDB / MySQL

```bash
# Install MariaDB server
ansible db -b -m apt -a "name=mariadb-server state=present"

# Start and enable MariaDB
ansible db -b -m service -a "name=mariadb state=started enabled=yes"

# Check MariaDB status
ansible db -b -m shell -a "mysqladmin status"

# Create a database
ansible db -b -m mysql_db -a "name=mydb state=present login_unix_socket=/var/run/mysqld/mysqld.sock"

# Drop a database
ansible db -b -m mysql_db -a "name=mydb state=absent login_unix_socket=/var/run/mysqld/mysqld.sock"

# Create a MySQL user
ansible db -b -m mysql_user -a "name=myuser password=secret priv='mydb.*:ALL' state=present login_unix_socket=/var/run/mysqld/mysqld.sock"

# Remove a MySQL user
ansible db -b -m mysql_user -a "name=myuser state=absent login_unix_socket=/var/run/mysqld/mysqld.sock"

# Check MySQL processlist
ansible db -b -m shell -a "mysql -e 'SHOW PROCESSLIST;'"
```

### PostgreSQL

```bash
# Install PostgreSQL
ansible db -b -m apt -a "name=postgresql state=present"

# Start PostgreSQL
ansible db -b -m service -a "name=postgresql state=started enabled=yes"

# Create a PostgreSQL database
ansible db -b -m postgresql_db -a "name=mydb state=present" -u postgres

# Create a PostgreSQL user
ansible db -b -m postgresql_user -a "name=myuser password=secret state=present" -u postgres

# Check PostgreSQL connections
ansible db -b -m shell -a "psql -U postgres -c 'SELECT count(*) FROM pg_stat_activity;'"
```

---

## 19. Docker Operations

```bash
# Check Docker version
ansible all -m shell -a "docker --version"

# List running containers
ansible all -b -m shell -a "docker ps"

# List all containers including stopped
ansible all -b -m shell -a "docker ps -a"

# Pull a Docker image
ansible all -b -m docker_image -a "name=nginx:latest source=pull"

# Run a container
ansible all -b -m docker_container -a "name=mynginx image=nginx state=started ports=80:80"

# Stop a container
ansible all -b -m docker_container -a "name=mynginx state=stopped"

# Remove a container
ansible all -b -m docker_container -a "name=mynginx state=absent"

# Check Docker disk usage
ansible all -b -m shell -a "docker system df"

# Prune unused Docker resources
ansible all -b -m shell -a "docker system prune -f"

# Get container logs
ansible all -b -m shell -a "docker logs mynginx --tail 50"

# Restart a container
ansible all -b -m docker_container -a "name=mynginx state=started restart=yes"
```

---

## 20. Inventory Patterns & Targeting

```bash
# All hosts
ansible all -m ping

# Specific group
ansible webservers -m ping

# Specific host
ansible web01 -m ping

# Multiple groups
ansible webservers:dbservers -m ping

# All hosts EXCEPT a group
ansible all:!dbservers -m ping

# Intersection of two groups (hosts in both)
ansible webservers:&staging -m ping

# Wildcard pattern
ansible web* -m ping

# Regex pattern (prefix with ~)
ansible ~web[0-9]+ -m ping

# Limit to first N hosts in a group
ansible all --limit "webservers[0:2]" -m ping

# Limit to a specific host within a run
ansible all --limit web01 -m ping

# Run against inline host (no inventory needed)
ansible -i "192.168.1.10," all -m ping

# Run against multiple inline hosts
ansible -i "192.168.1.10,192.168.1.11," all -m ping

# Run against localhost
ansible localhost -m ping -c local
```

---

## 21. Output & Verbosity Control

```bash
# Normal output
ansible all -m ping

# Verbose — shows SSH details
ansible all -m ping -v

# More verbose — shows module args
ansible all -m ping -vv

# Full debug output
ansible all -m ping -vvv

# Connection debug output
ansible all -m ping -vvvv

# Output as JSON
ansible all -m ping -o

# One-line output per host
ansible all -m command -a "uptime" --one-line

# Show only failed hosts
ansible all -m ping 2>&1 | grep FAILED

# Suppress warnings
ansible all -m ping -W

# Output to file
ansible all -m setup > facts.json
```

---

## 22. Parallel Execution & Throttling

```bash
# Run with 10 parallel forks (default is 5)
ansible all -m ping -f 10

# Run with maximum parallelism
ansible all -m ping -f 50

# Run serially (one host at a time)
ansible all -m ping -f 1

# Poll async task every 5 seconds, timeout 60s
ansible all -b -m apt -a "name=nginx state=latest" --async 60 --poll 5

# Fire and forget (don't wait for result)
ansible all -b -m shell -a "reboot" --async 0 --poll 0

# Batch deploy — 20 hosts at a time
ansible webservers -m shell -a "systemctl restart myapp" -f 20
```

---

## 23. Vault & Secrets

```bash
# Run playbook/ad-hoc with vault password prompt
ansible all -m ping --ask-vault-pass

# Run with vault password file
ansible all -m ping --vault-password-file ~/.vault_pass

# Use encrypted variable inline (requires vault setup)
ansible all -b -m user -a "name=john password={{ vault_john_password }}"

# Create encrypted string to use in playbook (not ad-hoc, but useful reference)
ansible-vault encrypt_string 'mysecretpassword' --name 'my_password'
```

---

## 24. Common Real-World One-Liners

```bash
# Reboot all servers and wait for them to come back
ansible all -b -m reboot -a "reboot_timeout=300"

# Check uptime across all servers
ansible all -m shell -a "uptime" --one-line

# Find servers running a specific kernel version
ansible all -m setup -a "filter=ansible_kernel" -o

# Disable SSH password auth on all servers
ansible all -b -m lineinfile -a "path=/etc/ssh/sshd_config regexp='^PasswordAuthentication' line='PasswordAuthentication no'"

# Restart SSH after config change
ansible all -b -m service -a "name=sshd state=restarted"

# Set timezone on all servers
ansible all -b -m timezone -a "name=Europe/Warsaw"

# Sync time with NTP
ansible all -b -m shell -a "chronyc makestep"

# Find which hosts have a file
ansible all -m stat -a "path=/etc/myapp.conf" -o | grep 'exists.*True'

# Check SSL certificate expiry
ansible webservers -m shell -a "echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -dates"

# Deploy SSH key to all servers at once
ansible all -b -m authorized_key -a "user=deploy key='{{ lookup('file', '~/.ssh/id_rsa.pub') }}'"

# Kill a zombie process on all servers
ansible all -b -m shell -a "ps aux | awk '/defunct/ {print $2}' | xargs -r kill -9"

# Clear swap on all servers
ansible all -b -m shell -a "swapoff -a && swapon -a"

# Check for servers that need a reboot (Ubuntu/Debian)
ansible all -m stat -a "path=/var/run/reboot-required" -o | grep 'exists.*True'

# Install security updates only (Ubuntu)
ansible all -b -m shell -a "apt-get -y --only-upgrade install $(apt-get --just-print upgrade | grep -i security | awk '{print $2}')"

# Get list of installed packages
ansible all -b -m shell -a "dpkg --get-selections | grep install"

# Find servers where a service is NOT running
ansible all -m shell -a "systemctl is-active nginx" --one-line | grep -v 'active'

# Add entry to /etc/hosts on all servers
ansible all -b -m lineinfile -a "path=/etc/hosts line='192.168.1.50 mydb.internal' state=present"

# Remove entry from /etc/hosts
ansible all -b -m lineinfile -a "path=/etc/hosts line='192.168.1.50 mydb.internal' state=absent"

# Register all servers to Zabbix (shell example)
ansible all -b -m shell -a "/usr/bin/zabbix_agentd --test"

# Bulk password reset (hashed)
ansible all -b -m user -a "name=john password='{{ hashed_password }}' update_password=always"
```

---

## Quick Reference Card

```
ansible <target> [flags] -m <module> -a "<args>"

TARGETS:        all | groupname | hostname | pattern
BECOME:         -b (sudo) | -K (ask password)
AUTH:           -u user | -k (ask SSH pass) | --private-key
MODULES:        ping | command | shell | copy | fetch | file
                apt | dnf | package | service | systemd | user
                group | cron | setup | git | uri | reboot
CONTROL:        -f N (forks) | -C (dry run) | -D (diff)
                -v/-vvv (verbose) | --limit | --async
```

---

*Cheat sheet based on Ansible for DevOps by Jeff Geerling (2nd Edition, 2022)*
*Covers Ansible core modules — community modules may require collections via `ansible-galaxy collection install`*
