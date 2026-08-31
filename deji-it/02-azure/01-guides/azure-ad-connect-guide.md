# Microsoft Entra Connect (Azure AD Connect) Operations Guide

**Target Audience:** IT Administrators & DevOps Engineers  
**Environment:** Hybrid Identity (On-Prem AD + Microsoft Entra ID)  
**Last Updated:** May 2026

---

## 1. Core Architecture & Data Flow

Entra Connect does not simply "copy" data; it processes it through a three-stage pipeline. Understanding this distinction is critical for troubleshooting stuck synchronizations or attribute flow issues.

### The Three-Stage Pipeline

Every synchronization cycle (Delta or Full) executes these steps in order:

| Stage | Name | Action | Scope | Analogy |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Import** | Reads changes from the connected source (AD or Azure). | Updates the **Connector Space (CS)** only. Does not touch the core database yet. | *Checking the mailbox and pulling out letters, but not opening them.* |
| **2** | **Sync** | Compares CS data against the **Metaverse (MV)**. Applies rules (joining, projecting, attribute flow). | Updates the Metaverse and stages changes in the CS for the outbound direction. | *Opening letters, reading them, and deciding what to file in the cabinet.* |
| **3** | **Export** | Pushes staged changes from the CS to the target system. | Actual data modification happens in AD or Entra ID. | *Walking to the filing cabinet to store the document or mailing a reply.* |

> **Note:** In the Synchronization Service Manager (`miisclient.exe`), you will often see operations listed as pairs (e.g., `Delta Import` followed immediately by `Delta Sync`). The `Export` phase usually follows automatically if changes were staged.

---

## 2. Synchronization Cycles & Intervals

Entra Connect runs two distinct types of cycles with different purposes and default frequencies.

### A. Delta Sync (The Routine Cycle)
*   **Purpose:** Detects and processes changes (new users, modified attributes, password changes) since the last run.
*   **Default Interval:** **30 Minutes**.
*   **Behavior:** Lightweight and fast. Designed for continuous operation.
*   **Customization:** Can be shortened, but caution is advised (see *Best Practices*).

### B. Full Sync (The Maintenance Cycle)
*   **Purpose:** Re-scans **every single object** in the connected directories to ensure absolute consistency between On-Prem and Cloud.
*   **Default Interval:** **7 Days**.
*   **Behavior:** Resource intensive (high CPU, Disk I/O, and Network usage).
*   **When to Run Manually:**
    *   After modifying Synchronization Rules.
    *   After restoring an AD Domain Controller from backup.
    *   If data drift is suspected (objects exist in AD but missing in Azure).
*   **Warning:** **Do not** schedule this to run frequently (e.g., daily). It puts unnecessary load on the infrastructure and can cause performance degradation.
![[Pasted image 20260516212018.png]]
---

## 3. Latency Expectations: What Waits and What Doesn't?

Not all changes wait for the 30-minute timer. Behavior depends on the attribute type.

| Change Type | Mechanism | Expected Latency | Wait for Timer? |
| :--- | :--- | :--- | :--- |
| **Password Reset** | Event-Driven (PHS) | **~2 Seconds** | **NO** |
| **Account Lockout** | Event-Driven | **~2 Seconds** | **NO** |
| **New User Creation** | Delta Sync Cycle | 30 Mins (Default) | **YES** |
| **Group Membership** | Delta Sync Cycle | 30 Mins (Default) | **YES** |
| **Attribute Update** | Delta Sync Cycle | 30 Mins (Default) | **YES** |
| **Display Name Change** | Delta Sync Cycle | 30 Mins (Default) | **YES** |

### Why Passwords are Instant
Password Hash Sync (PHS) monitors the Domain Controller's Security Event Log for specific password change events. When detected, it triggers an immediate push to Azure, bypassing the standard scheduler queue.

### How to Force Immediate Sync for Groups/Users
If you have added a user to a critical security group and cannot wait for the next cycle:

```powershell
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Delta