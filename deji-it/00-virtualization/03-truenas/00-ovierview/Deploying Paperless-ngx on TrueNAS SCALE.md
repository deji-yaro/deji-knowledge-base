## Why I Built This

If you're like me, you've spent years accumulating PDF documents - invoices, contracts, bank statements, receipts, and countless other important files. They're neatly organized in folders, meticulously named, and I can find them by filename without issue. But here's the problem that drove me crazy: **finding specific information within those documents**.

Need to know how much I paid for that HVAC repair in 2022? That's buried inside a PDF. Looking for my electricity bill from three months ago? I know it's in the "Utilities" folder, but which file? The address I need for a tax form? It's in there somewhere, but searching through dozens of PDFs manually is a nightmare.

That's why I deployed **Paperless-ngx** on my TrueNAS SCALE instance.

## What Problem It Solves

Paperless-ngx is essentially a **personal document management system** that:

1. **Indexes all text content** in your documents using Optical Character Recognition (OCR)
2. **Makes everything searchable** - by content, date, document type, tags, and more
3. **Automatically organizes** documents with tags, correspondents, and document types
4. **Consumes documents** from a designated folder, processing them without manual intervention

In my case, I have documents spread across various shares on my TrueNAS system. While my directory structure is logical, searching for specific information was painful. Paperless-ngx solves this by creating a searchable database of everything inside my PDFs.

## Why Paperless-ngx on TrueNAS

I chose Paperless-ngx for several compelling reasons:

- **Minimal resource footprint** - It runs happily on my TrueNAS instance without consuming significant computing power
- **"Scan once, benefit forever"** - The initial processing is the only intensive part; after that, searching is instant
- **TrueNAS App ecosystem** - It's available as an official app in the TrueNAS catalog, making deployment straightforward
- **Self-contained** - Everything runs within my network with no external dependencies or cloud uploads

## My Setup Details

Here's my specific deployment configuration:

| Component | Details |
|-----------|---------|
| **TrueNAS Version** | TrueNAS SCALE (Community Edition) |
| **App Name** | paperless-ngx |
| **Port** | 30070 |
| **Database** | Built-in PostgreSQL (random password) |
| **Cache** | Built-in Redis (random password) |
| **Secret Key** | Randomly generated string |
| **Container User/Group** | 568:568 (Apps user) |

### Storage Architecture

I've organized my storage carefully to maintain control over my original files while letting Paperless manage its own data:

```
/mnt/deji-random-hdd/deji-random-hdd/
├── deji-shares/          # My original, manually-organized documents (Paperless does NOT touch this)
└── paperless/
    ├── data/             # Paperless internal storage (indexes, database, processed originals, thumbnails)
    └── inbox/            # Consumption folder - drop documents here for processing
```

**Important Design Decision:** I deliberately keep my original document structure separate. Once Paperless processes a document, it removes it from the inbox and stores a copy in its own structure (within the `data/documents/originals/` directory). I made a conscious choice to maintain my original files in my `deji-shares` directory - even though this means storing duplicate data - because I prefer to keep my existing organization intact. This gives me the best of both worlds: my familiar folder structure AND Paperless's powerful search capabilities.

## Step-by-Step Deployment

### 1. Prepare Your Datasets

Before installing the app, set up your datasets with the proper permissions. TrueNAS SCALE apps run as user `apps` (UID 568) and group `apps` (GID 568).

1. In the TrueNAS web interface, navigate to **Storage** → **Datasets**
2. Create the following dataset structure:

```
/deji-random-hdd/paperless/
  ├── data/
  └── inbox/
```

3. For each dataset, set the **Dataset Preset** to **Apps** - this automatically configures the correct permissions

**Troubleshooting Tip:** If you encounter permission errors during installation, the Paperless container may attempt to change file ownership. A community-proven workaround is to set ownership via the TrueNAS shell:
```bash
sudo chown netdata: /mnt/deji-random-hdd/deji-random-hdd/paperless/
```
This has resolved PostgreSQL folder permission issues for many users.

### 2. Install the Paperless-ngx App

1. Navigate to **Apps** → **Discover Apps**
2. Search for `paperless-ngx`
3. Click **Install** on the official app

### 3. Configure the Application

#### Basic Settings

| Setting | My Value | Notes |
|---------|----------|-------|
| Application Name | `paperless-ngx` | Can be anything you prefer |
| Version | Latest | Use the default version |
| Web Port | `30070` | My chosen port |

#### Storage Configuration (Critical Step)

Map your host directories to the container's expected paths:

| Host Path | Container Mount Path | Purpose |
|-----------|---------------------|---------|
| `/mnt/deji-random-hdd/deji-random-hdd/paperless/data` | `/usr/src/paperless/data` | Database, indexes, logs, and processed documents |
| `/mnt/deji-random-hdd/deji-random-hdd/paperless/data` | `/usr/src/paperless/media` | Paperless expects separate `media` and `data` directories; I point both to the same location |
| `/mnt/deji-random-hdd/deji-random-hdd/paperless/inbox` | `/usr/src/paperless/consume` | The consumption folder where documents are dropped for processing |

Set **Permission** for each mount to `568:568` (Apps user/group).

#### User and Group Configuration

Under **Pod Security Context**:
- **runAsUser**: `568`
- **runAsGroup**: `568`
- **fsGroup**: `568`

This ensures the container processes files with the correct permissions.

#### Security Credentials

| Setting | Action |
|---------|--------|
| **Paperless Secret Key** | Generate a random string (I used `openssl rand -hex 32`) |
| **Paperless Admin User** | Create your admin username |
| **Paperless Admin Password** | Generate a strong password |
| **Paperless Admin Email** | Your email address |
| **Redis Password** | Generate a random password (avoid `#` character) |
| **PostgreSQL Password** | Generate a random password |

**Security Note:** Using randomly generated passwords for all components significantly reduces the attack surface. I generated each password independently using a password manager.

#### OCR Settings

My environment requires multilingual OCR support:
- **Paperless OCR Language**: `eng` (primary)
- **Paperless OCR Languages**: `pol jpn` (additional languages, space-separated)

This enables accurate text extraction from English, Polish, and Japanese documents.

#### Timezone

Set your timezone (e.g., `Europe/London`, `America/New_York`, `Asia/Tokyo`) for accurate document timestamps.

### 4. Complete the Installation

After entering all configurations:
1. Review all settings
2. Click **Save** or **Install**
3. Wait for TrueNAS to deploy the container (this may take a few minutes)

### 5. Verify the Deployment

1. **Check Status**: Ensure the app shows **Running** in the Apps list
2. **Access the Interface**: Navigate to `http://[your-truenas-ip]:30070`
3. **Login**: Use your admin credentials
4. **Test Consumption**: Place a test PDF in `/mnt/deji-random-hdd/deji-random-hdd/paperless/inbox` and verify it's processed automatically

## Future Improvements

My deployment is functional, but I'm planning several enhancements:

### 1. Reverse Proxy Setup
I'll be placing Paperless-ngx behind an **nginx reverse proxy** to:
- Enable HTTPS with Let's Encrypt certificates
- Provide clean URLs (e.g., `paperless.mydomain.com`)
- Handle SSL termination securely
- Potentially add authentication layers

### 2. Email Consumption
I plan to configure Paperless to **consume documents via email**:
- Set up an email account specifically for document intake
- Configure Paperless to poll this inbox
- Automatically process documents sent as attachments
- Enable email-based workflow: forward important documents to my Paperless email address

### 3. Automatic Tagging Rules
I want to implement intelligent auto-tagging:
- Create automatic tags based on correspondents (e.g., "Electric Company", "Landlord")
- Set up date-based tags (e.g., "2026", "Q1 2026")
- Configure rules for document types (e.g., "Invoice", "Receipt", "Contract")
- Use machine learning to suggest tags based on document content

### 4. Additional Ideas
If you're implementing this yourself, consider:

- **Backup Automation**: While TrueNAS snapshots are great, consider backing up the PostgreSQL database separately using `pg_dump` or the built-in Paperless export functionality
- **User Management**: Create additional users for family members or team members with appropriate permissions
- **Document Pre-processing**: Set up filename-based metadata extraction for documents that already have meaningful filenames
- **Scheduled Health Checks**: Implement monitoring to ensure the OCR worker is processing documents correctly
- **WebDAV Integration**: Connect Paperless to WebDAV for mobile document uploads

## Troubleshooting Common Issues

| Issue                      | Solution                                                                                         |
| -------------------------- | ------------------------------------------------------------------------------------------------ |
| Permission denied errors   | Verify `568:568` permissions on all mounted paths; use `sudo chown netdata:` as a workaround     |
| Redis connection failed    | Check that your Redis password doesn't contain `#` or other special characters                   |
| Documents not processing   | Verify the inbox mount path and that files have read permissions                                 |
| OCR fails on Japanese text | Ensure `jpn` is in the OCR languages list and Tesseract has the required language pack installed |
| App won't start            | Check the container logs in the TrueNAS UI for specific error messages                           |

## Final Thoughts

This deployment has transformed how I interact with my document collection. What was once a chore - digging through folders and opening PDFs individually - is now a simple search query. The initial setup takes minimal time and resources, and the ongoing maintenance is practically zero.

Paperless-ngx on TrueNAS SCALE represents the perfect balance of power and simplicity: enterprise-grade document management capabilities running on my home infrastructure with minimal overhead.

---

*Author's Note: This guide represents my personal deployment choices. Your environment may require different configurations based on your specific storage architecture and security requirements.*