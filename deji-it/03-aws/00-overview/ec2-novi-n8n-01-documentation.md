# EC2 Instance Documentation — `[INSTANCE_NAME]`

> **Region:** [AWS_REGION]
> **Account Owner ID:** [ACCOUNT_ID]
> **Last reviewed:** [DATE]

---

## 1. Instance Overview

| Field                      | Value                                              |
| -------------------------- | -------------------------------------------------- |
| **Instance ID**            | `[INSTANCE_ID]`                                    |
| **Instance Name**          | `[INSTANCE_NAME]`                                  |
| **Instance State**         | Running                                            |
| **Instance Type**          | [INSTANCE_TYPE]                                    |
| **AMI ID**                 | `[AMI_ID]`                                         |
| **AMI Name**               | `[AMI_NAME]`                                       |
| **Platform**               | Linux/UNIX                                         |
| **Launch Time**            | [LAUNCH_TIME]                                      |
| **Key Pair**               | `[KEY_PAIR_NAME]`                                  |
| **IMDSv2**                 | Required                                           |
| **Virtualization Type**    | HVM                                                |
| **Hypervisor**             | Xen                                                |
| **CPU Model**              | [CPU_MODEL]                                        |
| **CPU Architecture**       | x86_64                                             |
| **Number of vCPUs**        | [VCPU_COUNT]                                       |
| **RAM**                    | [RAM_TOTAL] total / [RAM_USED] used / [RAM_AVAIL] available |
| **Swap**                   | [SWAP_STATUS]                                      |
| **Boot Mode**              | legacy-bios                                        |
| **Tenancy**                | Default                                            |
| **Lifecycle**              | Normal                                             |
| **Monitoring**             | [MONITORING_STATUS]                                |
| **Termination Protection** | [TERMINATION_PROTECTION]                           |
| **Stop Protection**        | [STOP_PROTECTION]                                  |
| **Usage Operation**        | RunInstances                                       |

---

## 2. Network Configuration

| Field                    | Value                                                 |
| ------------------------ | ----------------------------------------------------- |
| **VPC ID**               | `[VPC_ID]`                                            |
| **Subnet ID**            | `[SUBNET_ID]`                                         |
| **Availability Zone**    | [AVAILABILITY_ZONE]                                   |
| **Public IPv4 Address**  | `[PUBLIC_IP]` (auto-assigned)                         |
| **Private IPv4 Address** | `[PRIVATE_IP]`                                        |
| **Private IP DNS Name**  | `[PRIVATE_DNS]`                                       |
| **Public DNS**           | `[PUBLIC_DNS]`                                        |
| **Elastic IP Addresses** | None assigned                                         |
| **IPv6 Address**         | None                                                  |
| **Network Interface**    | `[NETWORK_INTERFACE_ID]` (Device index 0)             |

---

## 3. Storage

| Field | Value |
|---|---|
| **Root Device Name** | `/dev/xvda` |
| **Root Device Type** | EBS |
| **EBS Optimization** | Disabled |
| **Volume ID** | `[VOLUME_ID]` |
| **Volume Size** | [VOLUME_SIZE] GiB |
| **Partition Layout** | `xvda1` ([ROOT_SIZE] GiB, `/`) · `xvda14` ([PART_SIZE] MiB) · `xvda15` ([EFI_SIZE] MiB, `/boot/efi`) |
| **Disk Usage (`/`)** | [USED_GB] GiB used / [FREE_GB] GiB free ([USAGE_PERCENT]%) |
| **Volume State** | In-use / Attached |
| **EBS Card Index** | 0 |
| **Encrypted** | [ENCRYPTION_STATUS] |
| **Attachment Time** | [ATTACHMENT_TIME] |

---

## 4. Security Groups

The instance is attached to **one security group** on the EC2 side.

### 4.1 `[EC2_SG_NAME]` — `[EC2_SG_ID]`

**Description:** [SG_DESCRIPTION]
**VPC:** `[VPC_ID]`

#### Inbound Rules

| Rule ID                 | Type       | Protocol | Port | Source                           | Notes                  |
| ----------------------- | ---------- | -------- | ---- | -------------------------------- | ---------------------- |
| `[RULE_ID_1]`           | SSH        | TCP      | 22   | `[ADMIN_IP_1]/32`                | [ADMIN_NOTES_1]        |
| `[RULE_ID_2]`           | SSH        | TCP      | 22   | `[ADMIN_IP_2]/32`                | [ADMIN_NOTES_2]        |
| `[RULE_ID_3]`           | Custom TCP | TCP      | 3000 | `[ALB_SG_ID]` ([ALB_SG_NAME])   | ALB → app port         |
| `[RULE_ID_4]`           | Custom TCP | TCP      | 5678 | `[ALB_SG_ID]` ([ALB_SG_NAME])   | ALB → webhook port     |
| `[RULE_ID_5]`           | SSH        | TCP      | 22   | `[ADMIN_IP_3]/32`                | [ADMIN_NOTES_3]        |

#### Outbound Rules

| Rule ID | Type | Protocol | Port | Destination | Notes |
|---|---|---|---|---|---|
| `[RULE_ID_6]` | All traffic | All | All | `0.0.0.0/0` | Full internet egress |
| `[RULE_ID_7]` | Custom TCP | TCP | 5678 | `[ALB_SG_ID]` ([ALB_SG_NAME]) | Return traffic to ALB |

---

### 4.2 `[ALB_SG_NAME]` — `[ALB_SG_ID]`

**Description:** Allow public HTTPS
**VPC:** `[VPC_ID]`
**Attached to:** Application Load Balancer `[ALB_NAME]`

#### Inbound Rules

| Rule ID                 | Type  | Protocol | Port | Source               | Notes      |
| ----------------------- | ----- | -------- | ---- | -------------------- | ---------- |
| `[RULE_ID_8]`           | HTTPS | TCP      | 443  | `[ALLOWED_IP_1]/32`  | [CLIENT_1] |
| `[RULE_ID_9]`           | HTTPS | TCP      | 443  | `[ALLOWED_IP_2]/32`  | [CLIENT_2] |

#### Outbound Rules

| Rule ID | Type | Protocol | Port | Destination |
|---|---|---|---|---|
| `[RULE_ID_10]` | All traffic | All | All | `0.0.0.0/0` |

---

## 5. Load Balancer

### 5.1 Overview — `[ALB_NAME]`

| Field | Value |
|---|---|
| **Name** | `[ALB_NAME]` |
| **Type** | Application Load Balancer (ALB) |
| **Status** | Active |
| **Scheme** | Internet-facing |
| **IP Address Type** | IPv4 |
| **VPC** | `[VPC_ID]` |
| **Hosted Zone** | `[HOSTED_ZONE_ID]` |
| **Date Created** | [CREATION_DATE] |
| **DNS Name** | `[ALB_DNS_NAME]` (A Record) |
| **ARN** | `[ALB_ARN]` |

### 5.2 Network Mapping

| Availability Zone | Subnet | Private IPv4 CIDR |
|---|---|---|
| [AZ_1] | `[SUBNET_1]` | Assigned from CIDR `[CIDR_1]` |
| [AZ_2] | `[SUBNET_2]` | Assigned from CIDR `[CIDR_2]` |

**VPC CIDR:** `[VPC_CIDR]`

### 5.3 Listener

| Protocol:Port | Default Action | Rules | SSL Certificate | Security Policy |
|---|---|---|---|---|
| HTTPS:443 | Forward to `[TARGET_GROUP_1]` (100%) | [RULE_COUNT] rules | `[CERT_DOMAIN]` | `[SECURITY_POLICY]` |

### 5.4 Listener Rules

| Priority | Condition | Action |
|---|---|---|
| Priority [N] | HTTP Host Header is `[SUBDOMAIN_1].[DOMAIN]` | Forward to target group `[TARGET_GROUP_2]` |
| Priority Default | If no other rule applies | Forward to target group `[TARGET_GROUP_1]` |

### 5.5 ALB Attributes

#### Traffic Configuration

| Attribute | Value |
|---|---|
| TLS version and cipher headers | Off |
| WAF fail open | Off |
| HTTP/2 | On |
| Connection idle timeout | [TIMEOUT] seconds |
| HTTP client keepalive duration | [KEEPALIVE] seconds |

#### Packet Handling

| Attribute | Value |
|---|---|
| Desync mitigation mode | Defensive |
| Drop invalid header fields | Off |
| X-Forwarded-For header | Append |
| Client port preservation | Off |
| Preserve host header | Off |

#### Availability Zone Routing

| Attribute | Value |
|---|---|
| Cross-zone load balancing | On |
| ARC zonal shift integration | Disabled |

#### Protection & Monitoring

| Attribute | Value |
|---|---|
| Deletion protection | Off |
| Access logs | Off |
| Connection logs | Off |
| Health check logs | Off |

---

## 6. Target Groups

### 6.1 `[TARGET_GROUP_1]`

| Field | Value |
|---|---|
| **ARN** | `[TG_ARN_1]` |
| **Target Type** | Instance |
| **Protocol:Port** | HTTP:[PORT_1] |
| **Protocol Version** | HTTP1 |
| **IP Address Type** | IPv4 |
| **VPC** | `[VPC_ID]` |
| **Load Balancer** | `[ALB_NAME]` |
| **Total Targets** | [TARGET_COUNT] |
| **Healthy** | [HEALTHY_COUNT] |
| **Unhealthy** | [UNHEALTHY_COUNT] |

#### Registered Targets

| Instance ID | Name | Port | Zone | Health Status |
|---|---|---|---|---|
| `[INSTANCE_ID]` | `[INSTANCE_NAME]` | [PORT_1] | [AZ] | ✅ Healthy |

#### Health Check Settings

| Field | Value |
|---|---|
| Protocol | HTTP |
| Path | `[HEALTH_PATH_1]` |
| Port | Traffic port |
| Healthy threshold | [HEALTHY_THRESHOLD] consecutive successes |
| Unhealthy threshold | [UNHEALTHY_THRESHOLD] consecutive failures |
| Timeout | [TIMEOUT] seconds |
| Interval | [INTERVAL] seconds |
| Success codes | [SUCCESS_CODES] |

---

### 6.2 `[TARGET_GROUP_2]`

| Field | Value |
|---|---|
| **ARN** | `[TG_ARN_2]` |
| **Target Type** | Instance |
| **Protocol:Port** | HTTP:[PORT_2] |
| **Protocol Version** | HTTP1 |
| **IP Address Type** | IPv4 |
| **VPC** | `[VPC_ID]` |
| **Load Balancer** | `[ALB_NAME]` |
| **Total Targets** | [TARGET_COUNT] |
| **Healthy** | [HEALTHY_COUNT] |
| **Unhealthy** | [UNHEALTHY_COUNT] |

#### Registered Targets

| Instance ID | Name | Port | Zone | Health Status |
|---|---|---|---|---|
| `[INSTANCE_ID]` | `[INSTANCE_NAME]` | [PORT_2] | [AZ] | ✅ Healthy |

#### Health Check Settings

| Field | Value |
|---|---|
| Protocol | HTTP |
| Path | `[HEALTH_PATH_2]` |
| Port | Traffic port |
| Healthy threshold | [HEALTHY_THRESHOLD] consecutive successes |
| Unhealthy threshold | [UNHEALTHY_THRESHOLD] consecutive failures |
| Timeout | [TIMEOUT] seconds |
| Interval | [INTERVAL] seconds |
| Success codes | [SUCCESS_CODES] |

---

## 7. Traffic Flow Diagram

```
Internet
    │
    ▼ HTTPS:443
┌─────────────────────────────┐
│   ALB: [ALB_NAME]          │
│   SG: [ALB_SG_NAME]        │
│   ([ALB_SG_ID])            │
└─────────────────────────────┘
    │
    ├── Rule 1: Host = [SUBDOMAIN_1].[DOMAIN]
    │       └──► Target Group: [TARGET_GROUP_2]  ──► [INSTANCE_NAME] : [PORT_2]
    │
    └── Default Rule: all other traffic
            └──► Target Group: [TARGET_GROUP_1]  ──► [INSTANCE_NAME] : [PORT_1]

EC2 Instance: [INSTANCE_NAME]
    SG: [EC2_SG_NAME] ([EC2_SG_ID])
    Accepts inbound only from:
      - ALB SG (ports [PORT_1], [PORT_2])
      - Admin IPs via SSH (port 22)
```

---

## 8. Connection / Access Guide

### SSH Access

SSH access to the instance is restricted to specific IP addresses:

```bash
# Admin IP #1
ssh -i [KEY_PAIR_NAME].pem admin@[PUBLIC_IP]   # from [ADMIN_IP_1]

# Admin IP #2
ssh -i [KEY_PAIR_NAME].pem admin@[PUBLIC_IP]   # from [ADMIN_IP_2]
```

> **Note:** SSH (port 22) is not open to the public internet. Access is only permitted from the whitelisted IPs defined in the `[EC2_SG_NAME]` security group inbound rules.

### Application Access (via ALB)

| Application | URL | Backend Port |
|---|---|---|
| [APP_1_NAME] (main) | `https://[ALB_DNS_NAME]` | [PORT_1] |
| [APP_2_NAME] | `https://[SUBDOMAIN_1].[DOMAIN]` | [PORT_2] |

> TLS is terminated at the ALB using the certificate for `[CERT_DOMAIN]` with [SECURITY_POLICY].

### Internal Communication

- The EC2 instance only accepts application traffic from the ALB security group (`[ALB_SG_ID]`)
- Direct public access to ports [PORT_1] or [PORT_2] on the EC2 instance is blocked
- Outbound traffic from the instance is unrestricted (`0.0.0.0/0`)

---

## 9. Hosted Applications

Both applications run as Docker containers managed via Docker Compose on the host VM.

### 9.1 `[APP_1_DOMAIN]` — [APP_1_DESCRIPTION]

| Field | Value |
|---|---|
| **Container name** | `[CONTAINER_1_NAME]` |
| **Image** | `[IMAGE_1_NAME]:[IMAGE_1_TAG]` |
| **Container ID** | `[CONTAINER_1_ID]` |
| **Status** | Running (since [START_DATE]) |
| **Host port** | `[PORT_1]` → container port `[CONTAINER_PORT_1]` |
| **Docker network** | `[NETWORK_1]` (`[NETWORK_CIDR_1]`) |
| **Container IP** | `[CONTAINER_IP_1]` |
| **Compose project** | `[COMPOSE_PROJECT]` |
| **Compose file** | `[COMPOSE_FILE_PATH]` |
| **Restart policy** | [RESTART_POLICY_1] |
| **Runtime user** | `[RUNTIME_USER]` |
| **Runtime version** | [RUNTIME_VERSION] |

#### Volume Mounts

| Host path | Container path | Access |
|---|---|---|
| `[HOST_PATH_1]` | `[CONTAINER_PATH_1]` | Read/Write ([MOUNT_DESC_1]) |
| `[HOST_PATH_2]` | `[CONTAINER_PATH_2]` | Read/Write ([MOUNT_DESC_2]) |

#### Environment Variables

| Variable | Value |
|---|---|
| `[ENV_VAR_1]` | `[ENV_VALUE_1]` |
| `[ENV_VAR_2]` | `[ENV_VALUE_2]` |
| `[ENV_VAR_3]` | `[ENV_VALUE_3]` |
| `[ENV_VAR_4]` | `[ENV_VALUE_4]` |
| `[ENV_VAR_5]` | `[ENV_VALUE_5]` |
| `[ENV_VAR_6]` | `[ENV_VALUE_6]` |
| `[ENV_VAR_7]` | `[ENV_VALUE_7]` |
| `[ENV_VAR_8]` | `[ENV_VALUE_8]` |
| `[ENV_VAR_9]` | `[ENV_VALUE_9]` |

#### Purpose

This [APP_1_NAME] instance is used by developer **[DEVELOPER_NAME]** to power automated [WORKFLOW_DESCRIPTION]. The system sends [BUSINESS_CONTEXT]. Sellers reply with an item name and quantity, which the automation processes further. The exact workflow logic, downstream integrations, and connected credentials are managed within the [APP_1_NAME] UI at `https://[APP_1_DOMAIN]`.

---

### 9.2 `[APP_2_DOMAIN]` — [APP_2_DESCRIPTION]

| Field | Value |
|---|---|
| **Container name** | `[CONTAINER_2_NAME]` |
| **Image** | `[IMAGE_2_NAME]:[IMAGE_2_TAG]` ([IMAGE_SIZE]) |
| **Container ID** | `[CONTAINER_2_ID]` |
| **Status** | Running (since [START_DATE]) |
| **Host port** | `[PORT_2]` → container port `[CONTAINER_PORT_2]` |
| **Web server** | [WEB_SERVER] [WEB_SERVER_VERSION] |
| **Docker network** | `[NETWORK_2]` (`[NETWORK_CIDR_2]`) |
| **Container IP** | `[CONTAINER_IP_2]` |
| **Restart policy** | [RESTART_POLICY_2] |
| **Volume mounts** | [VOLUME_MOUNT_STATUS] |

#### Purpose

This dashboard is a custom [WEB_SERVER]-served web application accessible to [USER_TYPE]. It provides a password-protected interface where [USER_TYPE] can upload `.csv` or Excel files (e.g. [FILE_TYPES]). Authentication credentials (email + password) are stored in a **[DATABASE_SERVICE]** instance — the exact [DATABASE_SERVICE] project URL and credentials should be retrieved from the source code of the `[IMAGE_2_NAME]` image or the [DATABASE_SERVICE] project dashboard.

> ⚠️ The `[IMAGE_2_NAME]` image is a locally built custom image (`[IMAGE_REGISTRY]/[IMAGE_2_NAME]:[IMAGE_2_TAG]`). Its Dockerfile and source code should be stored separately (e.g. in a Git repository). Ensure the build source is documented and version-controlled to allow rebuilding after a disaster recovery.

---

## 10. System Services

The following systemd services are confirmed running on the host:

| Service | Description |
|---|---|
| `docker.service` | Docker container engine |
| `containerd.service` | Container runtime |
| `ssh.service` | OpenBSD Secure Shell server |
| `systemd-networkd.service` | Network configuration |
| `systemd-resolved.service` | DNS resolution |
| `systemd-timesyncd.service` | Network time synchronization (NTP) |
| `systemd-journald.service` | System logging |
| `systemd-udevd.service` | Device event manager |
| `systemd-logind.service` | User login management |
| `unattended-upgrades.service` | Automatic security updates |
| `polkit.service` | Authorization manager |
| `dbus.service` | D-Bus system message bus |
| `getty@tty1.service` | Console TTY |
| `serial-getty@ttyS0.service` | Serial console |
| `user@[UID].service` | User session ([USER_NAME], UID [UID]) |

> **Note:** There are no application-level systemd services. Both `[APP_1_NAME]` and `[APP_2_NAME]` are managed entirely by Docker and rely on Docker's own restart policies (`[RESTART_POLICY_1]` and `[RESTART_POLICY_2]` respectively). Docker itself starts automatically via `docker.service` on boot.

---

## 11. Backup Configuration

### 11.1 Backup Plan — `[BACKUP_PLAN_NAME]`

| Field | Value |
|---|---|
| **Backup plan name** | `[BACKUP_PLAN_NAME]` |
| **Backup plan ID** | `[BACKUP_PLAN_ID]` |
| **Last modified** | [LAST_MODIFIED] |
| **Last runtime** | [LAST_RUNTIME] |
| **Backup vault** | `[VAULT_NAME]` |
| **Resource assigned** | `[INSTANCE_NAME]` (`[INSTANCE_ID]`) |
| **IAM role** | `[IAM_ROLE_ARN]` |
| **Resource ARN** | `[RESOURCE_ARN]` |

The backup plan contains **2 rules**: `[RULE_1_NAME]` and `[RULE_2_NAME]`.

### 11.2 Backup Rule — `[RULE_1_NAME]`

| Field | Value |
|---|---|
| **Frequency** | [RULE_1_FREQUENCY] |
| **Start within** | [START_WINDOW] hours |
| **Complete within** | [COMPLETE_WINDOW] days |
| **Total retention period** | [RETENTION_1] |
| **Backup vault** | [VAULT_NAME] |
| **Transition to cold storage** | [TRANSITION_1] |
| **Archive Amazon EBS snapshots** | [ARCHIVE_1] |
| **Continuous backup** | Disabled |
| **Malware scan mode** | None |
| **Logically air-gapped vault** | — |
| **Backup indexes** | Not indexed |

### 11.3 Backup Rule — `[RULE_2_NAME]`

| Field | Value |
|---|---|
| **Frequency** | [RULE_2_FREQUENCY] |
| **Start within** | [START_WINDOW] hours |
| **Complete within** | [COMPLETE_WINDOW] days |
| **Total retention period** | [RETENTION_2] |
| **Backup vault** | [VAULT_NAME] |
| **Transition to cold storage** | [TRANSITION_2] |
| **Archive Amazon EBS snapshots** | [ARCHIVE_2] |
| **Continuous backup** | Disabled |
| **Malware scan mode** | None |
| **Logically air-gapped vault** | — |
| **Backup indexes** | Not indexed |

### 11.4 Backup Vault — `[VAULT_NAME]`

| Field | Value |
|---|---|
| **Vault name** | [VAULT_NAME] |
| **Vault type** | Backup vault |
| **Vault ARN** | `[VAULT_ARN]` |
| **Creation date** | [VAULT_CREATION_DATE] |
| **KMS encryption key ID** | `[KMS_KEY_ID]` |
| **Vault lock** | Not configured |
| **Total recovery points** | [RECOVERY_POINT_COUNT] (as of [DATE]) |

Recovery points are created [FREQUENCY_DESC] and are all of type **Image (AMI)** from resource `[INSTANCE_NAME]`. All observed recovery points have status **Completed**.

### 11.5 Advanced Backup Settings

| Setting | Value |
|---|---|
| Application-consistent backup (Windows VSS) | Disabled |
| S3 backup settings — Back up ACLs | Enabled |
| S3 backup settings — Back up object tags | Enabled |

---

## 12. Disaster Recovery — Restore Guide

In the event of instance failure or data loss, follow these steps to restore `[INSTANCE_NAME]` from an AWS Backup recovery point.

### Step 1 — Identify a Recovery Point

1. Open the **AWS Console** and navigate to **AWS Backup → Vaults → [VAULT_NAME]**
2. In the **Recovery points** table, identify the most recent **Completed** recovery point for resource `[INSTANCE_NAME]`
3. Note the **Recovery point ID** (AMI ID, e.g. `image/ami-xxxxxxxx`) and its **Creation time**

### Step 2 — Initiate the Restore

1. Select the desired recovery point and click **Restore**
2. AWS Backup will present an EC2 launch configuration form. Use the following settings to match the original instance:

| Setting        | Value to use                      |
| -------------- | --------------------------------- |
| Instance type  | `[INSTANCE_TYPE]`                 |
| VPC            | `[VPC_ID]`                        |
| Subnet         | `[SUBNET_ID]` ([AZ])              |
| Security group | `[EC2_SG_ID]` ([EC2_SG_NAME])     |
| Key pair       | `[KEY_PAIR_NAME]`                 |
| IAM role       | `[IAM_ROLE_NAME]`                 |

3. Confirm and start the restore. AWS Backup will launch a new EC2 instance from the AMI snapshot.

### Step 3 — Validate the New Instance

1. Once the instance reaches **Running** state, verify the **Private IP** and update any references if needed
2. SSH into the new instance from a whitelisted IP to confirm services are running:
```bash
ssh -i [KEY_PAIR_NAME].pem admin@<new-public-ip>
```
3. Verify that [APP_1_NAME] (port [PORT_1]) and [APP_2_NAME] (port [PORT_2]) are responding

### Step 4 — Re-register with the Load Balancer Target Groups

The restored instance will have a **new Instance ID** and must be re-registered manually:

1. Go to **EC2 → Target Groups → `[TARGET_GROUP_1]`**
2. Click **Register targets**, select the new instance, set port to `[PORT_1]`, and confirm
3. Go to **Target Groups → `[TARGET_GROUP_2]`**
4. Click **Register targets**, select the new instance, set port to `[PORT_2]`, and confirm
5. Wait for health checks to pass (healthy threshold: [HEALTHY_THRESHOLD] consecutive successes at [INTERVAL]-second intervals)

### Step 5 — Deregister the Old Instance (if still present)

If the original failed instance is still registered in the target groups, deregister it to stop sending traffic to it:

1. In each target group, select the old instance and click **Deregister**

### Step 6 — Update Security Group SSH Rules (if IP changed)

If the new instance has a different public IP and SSH access needs updating, add/update the inbound rule on `[EC2_SG_ID]` accordingly.

> ⚠️ **Note:** The most recent daily backup is taken at **[BACKUP_TIME]**. Any data written after that time and before the failure will be lost. Monthly backups are retained for **[RETENTION_2]** and transition to cold storage after [TRANSITION_PERIOD] — these may take longer to restore.

---

## 13. Instance Tags

| Key | Value |
|---|---|
| Name | `[INSTANCE_NAME]` |
