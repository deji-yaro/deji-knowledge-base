
## Environment Setup

Always activate the virtual environment before running any command:

```bash
source ~/yt-dlp/bin/activate
```

If you get cookie decryption errors with Brave or Chrome, install this first:

```bash
pip install secretstorage
```

> **Note:** The virtual environment only isolates Python packages. Browser cookie databases on your host system are still fully accessible to `--cookies-from-browser`.

---

## Twitch Audio-Only Recording (MP3)

Records live stream audio directly as MP3 at maximum quality. No video is downloaded.

```bash
yt-dlp --cookies-from-browser brave \
  -f "bestaudio" \
  --extract-audio \
  --audio-format mp3 \
  --audio-quality 0 \
  "https://www.twitch.tv/CHANNELNAME"
```

**To stop recording:** Press `Ctrl+C`. The file finalizes automatically.

### Flag Breakdown

| Flag | What it does |
| :--- | :--- |
| `-f "bestaudio"` | Selects only the audio track from the HLS manifest |
| `--extract-audio` | Triggers post-processing to extract and convert audio |
| `--audio-format mp3` | Output format. Use `m4a` instead if you want lossless AAC copy |
| `--audio-quality 0` | Best VBR quality (~320kbps). Range is 0 (best) to 9 (worst) |

---

## YouTube Live Recording

### Record from Current Moment (Default Behavior)

Starts at the live edge. No backlog download.

```bash
yt-dlp --merge-output-format mkv "https://www.youtube.com/watch?v=VIDEO_ID"
```

### Record from Start of DVR Buffer

Captures everything available in YouTube's live buffer (typically 2–12 hours depending on streamer settings).

```bash
yt-dlp --live-from-start --merge-output-format mkv "https://www.youtube.com/watch?v=VIDEO_ID"
```

**Important caveats for `--live-from-start`:**

-   Buffer is finite. If a stream has been live for 8 hours but YouTube only retains 4 hours of DVR, you will only get those 4 hours.
-   Initial start is slower because yt-dlp must download all buffered segments before catching up to real-time.
-   Only works while the stream is still live. Once it ends, the DVR buffer disappears.

---

## Post-Processing Existing Files

### Extract Audio from an Existing MP4 (Lossless)

Copies the audio stream without re-encoding. Takes seconds regardless of file size.

```bash
ffmpeg -i input.mp4 -vn -c:a copy output.m4a
```

### Cut Video Segments Losslessly

Fast keyframe-based cut. Place `-ss` **before** `-i` for speed.

```bash
ffmpeg -i input.mp4 -ss 00:01:23 -to 00:02:45 -c copy segment.mp4
```

Frame-accurate cut. Re-encodes video but gives exact frame boundaries. Slower.

```bash
ffmpeg -ss 00:01:23 -to 00:02:45 -i input.mp4 \
  -c:v libx264 -crf 18 -c:a copy segment.mp4
```

### Merge Separate Video and Audio Streams

When yt-dlp downloads DASH streams as separate files:

```bash
ffmpeg -i video.f137.mp4 -i audio.f140.m4a -c copy output.mkv
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `Precondition check failed` or `No video formats found` | Outdated yt-dlp | Run `pip install --upgrade yt-dlp` |
| `HTTP 403 Forbidden` on HLS segments | Stream token expired | Re-run yt-dlp to get a fresh URL. Never reuse old extracted URLs directly with ffmpeg. |
| `secretstorage not available` | Missing system keyring module | Run `pip install secretstorage` |
| "Commercial break in progress" warnings during Twitch download | Twitch server-side ad insertion (SSAI) markers in the raw HLS playlist | Normal behavior. Use `--cookies-from-browser` to suppress. Warnings are cosmetic if the download completes successfully. |
| Cookie decryption failures | Encrypted browser store inaccessible | Install `secretstorage`. Ensure the browser is not running during extraction. |

---

## Format Selection Quick Reference

| Goal | Command Fragment |
| :--- | :--- |
| Best video + audio (auto-merge) | *(default, no flag needed)* |
| Audio only | `-f "bestaudio"` |
| Max 1080p video + best audio | `-f "bestvideo[height<=1080]+bestaudio"` |
| Specific resolution | `-f "bestvideo[height=720]+bestaudio"` |
| Native container, no re-encode | `--merge-output-format mkv` or `mp4` |

---

## Key Concepts

-   **yt-dlp** is the extractor and orchestrator. It handles authentication, API calls, and format negotiation across 1,800+ sites.
-   **ffmpeg** is the media processing engine. It handles decoding, encoding, muxing, demuxing, and streaming protocols (HLS, DASH, RTMP).
-   yt-dlp calls ffmpeg as a subprocess when merging or converting. They are completely separate tools.
-   Virtual environments isolate Python packages only. They do not block access to system files or browser data.
-   Live streams use HLS/DASH with short-lived tokens tied to your IP and expiration time. Always go through yt-dlp to get fresh URLs; never reuse extracted URLs directly with ffmpeg.