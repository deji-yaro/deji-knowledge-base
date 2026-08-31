Here is a concise guide for using **ReconFTW**, tailored for your domain scanning needs.

#### 1. Prerequisites
*   **OS:** Ubuntu/Debian (Recommended for tool compatibility).
*   **Dependencies:** Git, Docker (optional but recommended for isolation), or standard Linux tools (`curl`, `wget`, `python3`).
*   **API Keys:** For best results, configure API keys in `config.yaml` for services like Shodan, Censys, and VirusTHere is a concise guide for using **ReconFTW**, tailored for your domain scanning needs.

### ReconFTW Quick Start Guide

#### 1. Prerequisites
*   **OS:** Ubuntu/Debian (Recommended for tool compatibility).
*   **Dependencies:** Git, Docker (optional but recommended for isolation), or standard Linux tools (`curl`, `wget`, `python3`).
*   **API Keys:** For best results, configure API keys in `config.yaml` for services like Shodan, Censys, and VirusTotal.

#### 2. Installation
```bash
# Clone the repository
git clone https://github.com/six2dez/reconftw.git
cd reconftw

# Install dependencies (if not using Docker)
./install.sh
```

#### 3. Basic Usage
ReconFTW uses a simple flag-based system. The most common modes are:

| Mode | Flag | Description |
| :--- | :--- | :--- |
| **Subdomain Enumeration** | `-d` | Target a single domain. |
| **List Scan** | `-l` | Target a list of domains from a file. |
| **Full Recon** | `-m all` | Runs all modules (subdomains, ports, vulns, etc.). |
| **Quick Scan** | `-m quick` | Runs only essential subdomain and port checks. |

#### 4. Common Commands

**Scan a single domain (Full Recon):**
```bash
./reconftw.sh -d example.com -m all
```

**Scan a single domain (Quick/Subdomains only):**
```bash
./reconftw.sh -d example.com -m subdomains
```

**Scan multiple domains from a file:**
```bash
./reconftw.sh -l domains.txt -m all
```

**Resume a failed scan:**
```bash
./reconftw.sh -d example.com -m all --resume
```

#### 5. Output Structure
Results are saved in the `output/` directory:
*   `output/example.com/`: Main folder for the target.
*   `subdomains/`: Found subdomains.
*   `ports/`: Open ports and services.
*   `vulnerabilities/`: Potential security issues found.

#### 6. Pro Tips for Your Workflow
*   **Config File:** Edit `config.yaml` to enable/disable specific tools (e.g., disable heavy vuln scanners if you only want asset discovery).
*   **Docker:** If you want to keep your host clean, use the provided `docker-compose.yml`:
    ```bash
    docker-compose run --rm reconftw -d example.com -m all
    ```
*   **AWS Integration:** Since you're moving to AWS, you can pipe the `subdomains.txt` output into Route53 health checks or use it to populate your AWS WAF allowed lists.

Let me know if you need help configuring the `config.yaml` for specific tools like `nuclei` or `httpx`.otal.

#### 2. Installation
```bash
# Clone the repository
git clone https://github.com/six2dez/reconftw.git
cd reconftw

# Install dependencies (if not using Docker)
./install.sh
```

#### 3. Basic Usage
ReconFTW uses a simple flag-based system. The most common modes are:

| Mode | Flag | Description |
| :--- | :--- | :--- |
| **Subdomain Enumeration** | `-d` | Target a single domain. |
| **List Scan** | `-l` | Target a list of domains from a file. |
| **Full Recon** | `-m all` | Runs all modules (subdomains, ports, vulns, etc.). |
| **Quick Scan** | `-m quick` | Runs only essential subdomain and port checks. |

#### 4. Common Commands

**Scan a single domain (Full Recon):**
```bash
./reconftw.sh -d example.com -m all
```

**Scan a single domain (Quick/Subdomains only):**
```bash
./reconftw.sh -d example.com -m subdomains
```

**Scan multiple domains from a file:**
```bash
./reconftw.sh -l domains.txt -m all
```

**Resume a failed scan:**
```bash
./reconftw.sh -d example.com -m all --resume
```

#### 5. Output Structure
Results are saved in the `output/` directory:
*   `output/example.com/`: Main folder for the target.
*   `subdomains/`: Found subdomains.
*   `ports/`: Open ports and services.
*   `vulnerabilities/`: Potential security issues found.

#### 6. Pro Tips for Your Workflow
*   **Config File:** Edit `config.yaml` to enable/disable specific tools (e.g., disable heavy vuln scanners if you only want asset discovery).
*   **Docker:** If you want to keep your host clean, use the provided `docker-compose.yml`:
    ```bash
    docker-compose run --rm reconftw -d example.com -m all
    ```
*   **AWS Integration:** Since you're moving to AWS, you can pipe the `subdomains.txt` output into Route53 health checks or use it to populate your AWS WAF allowed lists.

Let me know if you need help configuring the `config.yaml` for specific tools like `nuclei` or `httpx`.