#### 1. Preparing Your Datasets

Before installing the app, ensure your datasets have the correct permissions. TrueNAS SCALE apps typically run with user `apps` (UID `568`) and group `apps` (GID `568`).

*   **Dataset Preset**: When creating the datasets (`paperless/data`, `paperless/inbox`), set the **Dataset Preset** to **Apps**. This automatically configures the correct permissions for group `568`.
*   **Permission Troubleshooting**: If you encounter "permission denied" errors during installation, the Paperless container might try to change file ownership. A community workaround is to manually set ownership to the `netdata` user via the TrueNAS shell: `sudo chown netdata: /mnt/deji-random-hdd/deji-random-hdd/paperless/`. This can resolve startup failures related to PostgreSQL folder permissions.

#### 2. Installing the Paperless-ngx App

1.  In the TrueNAS SCALE web interface, go to the **Apps** section.
2.  Click **Discover Apps** and search for `paperless-ngx`.
3.  Click **Install** on the official Paperless-ngx app.

#### 3. Configuring the App

This is the critical part. Use the random passwords you generated for security.

*   **Application Name**: `paperless-ngx` (or your preferred name).
*   **Version**: Keep the default (latest).
*   **Port**: Set **Web Port** to `30070` as you specified.

**Storage Configuration (Critical Step)**

You need to map your host paths to the correct paths inside the container:

| Host Path (Your Setup) | Mount Path in Container      | Purpose                                                                                                                          |
| :--------------------- | :--------------------------- | :------------------------------------------------------------------------------------------------------------------------------- |
| [PATH]                 | `/usr/src/paperless/data`    | Stores database, indexes, logs, and the `originals`/`thumbnails` subdirectories.                                                 |
| [PATH]                 | `/usr/src/paperless/media`   | Paperless expects separate `media` and `data` directories; point both to the same host path if you want everything in one place. |
| [PATH]                 | `/usr/src/paperless/consume` | The "drop-off" folder for documents to be processed.                                                                             |

Set **Permission** for each to `568:568` (Apps user/group) to ensure write access.

**User and Group Configuration**

Under **Pod Security Context**:
*   **runAsUser**: `568`
*   **runAsGroup**: `568`
*   **fsGroup**: `568`

This ensures the container's user matches the host directory permissions.

**General Settings and Credentials**

*   **Paperless Secret Key**: Enter the **randomly generated** string you created.
*   **Paperless Admin User**: Enter your desired admin username.
*   **Paperless Admin Password**: Enter the strong password you generated.
*   **Paperless Admin Email**: Enter your email address.
*   **Paperless OCR Language**: Set to `eng` as the primary. For additional languages (Polish, Japanese), enter `pol jpn` in the **Paperless OCR Languages** field (space-separated).
*   **Paperless Timezone**: Set your timezone (e.g., `Europe/London`, `America/New_York`).

**Redis and Database**

The app will handle the internal Redis and PostgreSQL services. You must enter the random passwords you generated:
*   **Redis Password**: Enter the generated password. **Note**: Avoid using the `#` character in passwords, as it has been reported to cause connection failures.
*   **PostgreSQL Password**: Enter the generated password for the database user `paperless`.

#### 4. Completing the Installation

After filling in all the details, click **Save** or **Install** at the bottom of the page. TrueNAS will begin deploying the app.

#### 5. Post-Installation Check

*   **Access**: Once the app status shows **Running**, access it via your browser at `http://[your-truenas-ip]:30070`.
*   **Login**: Use the Admin User and Password you configured.
*   **Test Consumption**: Place a test PDF file into `/mnt/deji-random-hdd/deji-random-hdd/paperless/inbox`. Paperless should automatically process it and move it to its internal storage within the `data` directory, confirming everything works.

### Recommendations

For a more robust setup, you can create a separate dataset for PostgreSQL to avoid storing the database file within the main data directory. Since you already have your backup approach, this is optional but can simplify management.

Regarding your double-storage approach – creating separate directories for original files and the Paperless inbox is a valid strategy. Many community members also prefer this manual control.

### Key Takeaways

*   The **Apps** dataset preset is crucial for handling TrueNAS permissions seamlessly.
*   Setting the correct `runAsUser`/`fsGroup` to `568` prevents many common permission errors.
*   Using special characters like `#` in the Redis password can cause deployment failure.
*   The `data` and `media` mount paths are intentionally both pointing to your main `paperless/data` directory to centralize all Paperless files.
