Using Snap for RustScan gives you the latest upstream build without compiling. Nmap must be installed separately since Snap packages are sandboxed and can't call system binaries directly.

#### Step 1: Install Both Tools
```bash
# RustScan via Snap (latest stable)
sudo snap install rustscan

# Nmap via APT (required for service detection)
sudo apt install nmap -y

# Verify both are accessible
rustscan --version
nmap --version
```

#### Step 2: Basic Full Port Scan + Auto-Nmap
```bash
# Scan all 65,535 ports, then auto-run Nmap on open ones
rustscan -a 185.207.164.216 --ulimit 5000 -- -sV -O
```

**How this works:**
-   RustScan discovers open ports asynchronously (~3 seconds for full range)
-   The `--` separator passes everything after it as Nmap arguments
-   RustScan automatically substitutes `{{port}}`, `{{ip}}`, and `{{ipversion}}` into the Nmap command
-   Default Nmap template: `nmap -vvv -p {{port}} -{{ipversion}} {{ip}} -sV -O`

#### Step 3: Custom Nmap Arguments
Override the default Nmap behavior with custom flags:

```bash
# Aggressive scan with OS detection + script scanning
rustscan -a 185.207.164.216 --ulimit 5000 -- -A -T4

# UDP scan on discovered TCP ports (uncommon but useful)
rustscan -a 185.207.164.216 --ulimit 5000 -- -sU -sV

# Specific Nmap scripts only
rustscan -a 185.207.164.216 --ulimit 5000 -- --script=vuln,auth

# Skip Nmap entirely (raw port list only)
rustscan -a 185.207.164.216 --ulimit 5000 --no-nmap
```

#### Step 4: Batch Scanning Multiple Targets
```bash
# From file (one IP per line)
rustscan -a targets.txt --ulimit 5000 -- -sV -oN results.nmap

# CIDR range
rustscan -a 185.207.164.0/24 --ulimit 5000 -- -sV
```

#### Critical Caveats
-   **Snap Sandbox:** RustScan Snap *cannot* access Nmap if Nmap is also installed via Snap. **Always install Nmap via APT.**
-   **ULimit:** Without `--ulimit 5000`, RustScan defaults to 3000 file descriptors, which caps simultaneous connections and slows full-range scans significantly. Set to 5000–10000 for best performance.
-   **Rate Limiting:** If scanning external hosts, add `-b 500` (batch size) to avoid triggering firewall rate limits:
    ```bash
    rustscan -a 185.207.164.216 --ulimit 5000 -b 500 -- -sV
    ```
-   **Output Files:** Nmap output flags (`-oN`, `-oX`, `-oA`) work normally through the `--` passthrough. RustScan itself doesn't save results — rely on Nmap's output options for persistence. are sandboxed and can't call system binaries directly.

#### Step 1: Install Both Tools
```bash
# RustScan via Snap (latest stable)
sudo snap install rustscan

# Nmap via APT (required for service detection)
sudo apt install nmap -y

# Verify both are accessible
rustscan --version
nmap --version
```

#### Step 2: Basic Full Port Scan + Auto-Nmap
```bash
# Scan all 65,535 ports, then auto-run Nmap on open ones
rustscan -a 185.207.164.216 --ulimit 5000 -- -sV -O
```

**How this works:**
-   RustScan discovers open ports asynchronously (~3 seconds for full range)
-   The `--` separator passes everything after it as Nmap arguments
-   RustScan automatically substitutes `{{port}}`, `{{ip}}`, and `{{ipversion}}` into the Nmap command
-   Default Nmap template: `nmap -vvv -p {{port}} -{{ipversion}} {{ip}} -sV -O`

#### Step 3: Custom Nmap Arguments
Override the default Nmap behavior with custom flags:

```bash
# Aggressive scan with OS detection + script scanning
rustscan -a 185.207.164.216 --ulimit 5000 -- -A -T4

# UDP scan on discovered TCP ports (uncommon but useful)
rustscan -a 185.207.164.216 --ulimit 5000 -- -sU -sV

# Specific Nmap scripts only
rustscan -a 185.207.164.216 --ulimit 5000 -- --script=vuln,auth

# Skip Nmap entirely (raw port list only)
rustscan -a 185.207.164.216 --ulimit 5000 --no-nmap
```

#### Step 4: Batch Scanning Multiple Targets
```bash
# From file (one IP per line)
rustscan -a targets.txt --ulimit 5000 -- -sV -oN results.nmap

# CIDR range
rustscan -a 185.207.164.0/24 --ulimit 5000 -- -sV
```

#### Critical Caveats
-   **Snap Sandbox:** RustScan Snap *cannot* access Nmap if Nmap is also installed via Snap. **Always install Nmap via APT.**
-   **ULimit:** Without `--ulimit 5000`, RustScan defaults to 3000 file descriptors, which caps simultaneous connections and slows full-range scans significantly. Set to 5000–10000 for best performance.
-   **Rate Limiting:** If scanning external hosts, add `-b 500` (batch size) to avoid triggering firewall rate limits:
    ```bash
    rustscan -a 185.207.164.216 --ulimit 5000 -b 500 -- -sV
    ```
-   **Output Files:** Nmap output flags (`-oN`, `-oX`, `-oA`) work normally through the `--` passthrough. RustScan itself doesn't save results — rely on Nmap's output options for persistence.