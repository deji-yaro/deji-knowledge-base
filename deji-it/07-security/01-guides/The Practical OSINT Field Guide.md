Here is the updated **Practical OSINT Field Guide**, incorporating the Instagram bypass technique and browser hygiene protocols.

***

# The Practical OSINT Field Guide
**Author:** Deji  
**Focus:** Image Analysis, Geo-Location, Platform-Specific Metadata, and Infrastructure Recon

## 1. Image Metadata Extraction (EXIF & Beyond)

Metadata is the digital fingerprint of an image. While many platforms strip this data, original files often retain critical information about the device, location, and time of capture.

### CLI Tools (Local Analysis)
*   **ExifTool (The Gold Standard):** Comprehensive extraction of GPS, timestamps, camera models, and software used.
    ```bash
    exiftool image.jpg                # Basic info
    exiftool -GPS* image.jpg          # GPS coordinates only
    exiftool -a -u -g1 image.jpg      # All tags, including unknown/proprietary
    ```
*   **Identify (ImageMagick):** Quick verification of file format, dimensions, and color profile.
*   **Jhead:** Lightweight alternative for JPEG-specific headers.

### Web-Based Tools (Remote Analysis)
*   **Jeffrey’s Image Metadata Viewer:** Browser-based interface for ExifTool.
*   **FotoForensics:** Provides Error Level Analysis (ELA) to detect edits/compression artifacts alongside metadata.
*   **Metapicz / Verexif:** Simple drag-and-drop viewers for quick checks.

### ⚠️ Critical Caveat
**Social Media Sanitization:** Platforms like Facebook, Instagram, Twitter, and Discord typically strip EXIF data upon upload. Always verify if you are analyzing the **original file** or a processed copy. If the file is from a social platform, metadata analysis will likely yield empty results.

---

## 2. GeoOSINT: Visual Triangulation Methodology

When metadata is absent, visual analysis becomes the primary tool. Success relies on identifying immutable environmental details.

### The "Small Details" Framework
1.  **Reflections:** Windows, puddles, and car mirrors provide reverse-perspective clues of what is behind the photographer.
2.  **Infrastructure Markers:** 
    *   **Sidewalk Bricks:** Patterns vary by municipality and era.
    *   **Power Poles:** Configuration (transformer placement, wire count) is region-specific.
    *   **Manhole Covers:** Often stamped with city names or utility providers.
3.  **Architectural Signatures:** Roof styles, window frames, and door designs can narrow down countries or even neighborhoods.
4.  **Vegetation:** Tree species and landscaping indicate climate zones.
5.  **Signage:** Language, regulatory signs (speed limits, parking rules), and brand presence.

### Tool Stack for Verification
*   **Google Earth Pro:** Use historical imagery to see changes over time and 3D buildings for perspective matching.
*   **Google Maps Street View:** Ground-level verification of architectural details.
*   **Yandex Maps:** Superior coverage and often more recent imagery for Eastern Europe (e.g., Poland).
*   **Geoportal.gov.pl:** National geoportal for Poland; often contains high-resolution local aerial photography not found on global platforms.
*   **SunCalc.org:** Determine the time of day based on shadow angles and direction.

### Overcoming Imagery Discrepancies
*   **Satellite vs. Aerial:** Satellite imagery may show "green areas" where stores exist due to outdated stitching or cloud cover masking. Cross-reference with local municipal maps.
*   **Alignment Issues:** If Google Maps seems misaligned, use multiple sources (Bing, Yandex, Local Gov portals) to triangulate the true position.

---

## 3. Facial Recognition OSINT

Facial recognition is powerful but limited by platform privacy measures.

### Primary Tool: PimEyes
*   **Strengths:** Indexes non-social media sites (news, forums, blogs). Provides source URLs for matches. High accuracy with partial faces.
*   **Limitations:** Paid service for full results. Does **not** index major social platforms (Facebook, Instagram, LinkedIn) due to anti-scraping protections.
*   **Workflow:** Use the free tier to identify *which* domains host the image, then manually investigate those sites. The URL trail is often more valuable than the face match itself.

### Alternative Tools
*   **FaceCheck.ID:** Better social media coverage but lower accuracy.
*   **Search4Faces:** Specialized for VK, OK, and TikTok (strong for Eastern Europe).
*   **Yandex Images:** Surprisingly effective facial matching for Russian/Eastern European targets.

### Ethical & Legal Boundaries
*   **GDPR (EU):** Facial data is biometric data. Processing without consent may violate Article 9.
*   **BIPA (Illinois, US):** Strict regulations on biometric collection.
*   **Best Practice:** Document lawful basis for investigation. Never use for harassment or unauthorized surveillance.

---

## 4. Platform-Specific OSINT

### Discord CDN Analysis
Discord’s CDN links embed structured data that can reveal upload times and file origins.

#### URL Structure Breakdown
`https://cdn.discordapp.com/attachments/[CHANNEL_ID]/[MESSAGE_ID]/[FILENAME]?[PARAMS]`

| Segment | Example | Insight |
| :--- | :--- | :--- |
| **Channel ID** | `1446966330040258591` | Identifies the specific channel. Can be used to locate the server if access is available. |
| **Message ID** | `1524699533559201844` | A **Snowflake**. Contains the exact millisecond of upload. |
| **Filename** | `20260709_105055.jpg` | Original name. Often contains timestamps (YYYYMMDD_HHMMSS). |
| **Params** | `?ex=...&is=...` | Security tokens for link expiration. |

#### Decoding the Snowflake (Upload Time)
Discord IDs are time-based. The first 42 bits represent milliseconds since the Discord Epoch (Jan 1, 2015).

```python
import datetime

def decode_snowflake(snowflake_id):
    discord_epoch = 1420070400000
    timestamp_ms = (int(snowflake_id) >> 22) + discord_epoch
    return datetime.datetime.utcfromtimestamp(timestamp_ms / 1000.0)

print(decode_snowflake("1524699533559201844"))
```

#### Filename Pattern Analysis
*   **Android/iOS:** `IMG_YYYYMMDD_HHMMSS.jpg`, `PXL_...`
*   **WhatsApp:** `WAVID_YYYY-MM-DD_at_HH.MM.SS.jpg`
*   **Telegram:** `photo_YYYY-MM-DD_HH-MM-SS.jpg`
*   **Generic:** `image.png`, `download.jpg` (Indicates renaming or processing).

### Instagram Bypass Techniques
Instagram aggressively blocks unauthenticated access and scraping. However, third-party viewers can bypass these restrictions for public profiles.

*   **Primary Tool: Imginn (`https://imginn.com/`)**
    *   **Function:** Allows viewing of public Instagram profiles, posts, stories, and tagged photos without an account.
    *   **Advantage:** No login required, no cookies tracked, and avoids triggering Instagram's "suspicious activity" locks on your personal account.
    *   **Limitation:** Only works for **public** profiles. Private accounts remain inaccessible.
*   **Alternative:** **Picuki** or **Inflact** (some features may require payment or have stricter rate limits).

---

## 5. Browser Hygiene & OPSEC

Efficient OSINT requires maintaining a clean digital environment to avoid contamination of results and protect your identity.

### Incognito/Private Mode Protocol
*   **Why:** Prevents the browser from saving cookies, history, cache, or form data. This ensures that subsequent searches are not influenced by previous sessions (personalization algorithms) and leaves no local trace of your investigation.
*   **How:** Use `Ctrl+Shift+N` (Chrome/Edge) or `Ctrl+Shift+P` (Firefox) to open a new private window for every distinct target or session.
*   **Limitation:** Incognito mode does **not** hide your IP address from the websites you visit or your ISP. It only protects local privacy.

### Advanced Browser Hygiene
*   **Dedicated Profiles:** Create a separate browser profile specifically for OSINT work. Keep it logged out of all personal accounts (Google, Facebook, etc.).
*   **Container Tabs (Firefox):** Use Multi-Account Containers to isolate different investigations from each other.
*   **User-Agent Switching:** Occasionally rotate your User-Agent string to avoid being fingerprinted as a single automated bot, though modern browsers make this harder.

---

## 6. Verification Workflow

1.  **Cross-Reference:** Never rely on a single source. Match visual clues with map data.
2.  **Time Correlation:** Compare EXIF timestamps, filename timestamps, and upload times (Snowflakes). Discrepancies indicate editing or delayed sharing.
3.  **Source Validation:** Verify if the image is original or a repost. Use reverse image search (Yandex, TinEye) to find earlier instances.
4.  **Document Failures:** Record what didn’t work (e.g., failed face matches) to refine future methodologies.

***

This version now includes the specific Instagram workaround and essential browser hygiene practices. Is there any other specific tool or technique you've used that should be added before we finalize this draft?