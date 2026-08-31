# Clair Obscur: Expedition 33 — Complete Linux Setup & Troubleshooting Guide
### Running a non-Steam Windows game via Lutris (Flatpak) + GE-Proton on Ubuntu/GNOME/Wayland

---

## Table of Contents

1. [System Requirements & Tested Configuration](#1-system-requirements--tested-configuration)
2. [Prerequisites — What to Install First](#2-prerequisites--what-to-install-first)
3. [Lutris Game Configuration](#3-lutris-game-configuration)
4. [Environment Variables — Full Reference](#4-environment-variables--full-reference)
5. [Essential First-Time Setup Steps](#5-essential-first-time-setup-steps)
6. [Troubleshooting — Issues Encountered & Solutions](#6-troubleshooting--issues-encountered--solutions)
   - [Issue 1: Horrendous Periodic FPS Drops Every 1–2 Seconds](#issue-1-horrendous-periodic-fps-drops-every-12-seconds)
   - [Issue 2: mfplat.dll Crash — MFGetConfigurationDWORD](#issue-2-mfplatdll-crash--mfgetconfigurationdword)
   - [Issue 3: Proton Experimental Fails — steamclient Not Found](#issue-3-proton-experimental-fails--steamclient-not-found)
   - [Issue 4: GE-Proton Version Downgrade Breaks the Prefix](#issue-4-ge-proton-version-downgrade-breaks-the-prefix)
   - [Issue 5: Visual C++ Runtime Error on First Launch](#issue-5-visual-c-runtime-error-on-first-launch)
   - [Issue 6: Audio Stutter and Visual Hitching](#issue-6-audio-stutter-and-visual-hitching)
7. [How to Read Lutris Logs](#7-how-to-read-lutris-logs)
8. [Managing Wine/Proton Versions with ProtonUp-Qt](#8-managing-wineproton-versions-with-protonup-qt)
9. [Final Working Configuration Summary](#9-final-working-configuration-summary)
10. [Glossary](#10-glossary)

---

## 1. System Requirements & Tested Configuration

This guide was developed and tested on the following hardware and software. Your mileage may vary on different setups, but the troubleshooting logic applies broadly.

### Hardware

| Component | Specification |
|---|---|
| CPU | Intel Core i5-7600K @ 3.80GHz (4 cores / 4 threads) |
| RAM | 32 GB DDR4 |
| Swap | 8 GB |
| GPU | AMD Radeon RX 6750 XT |
| GPU Driver | RADV (Mesa 26.0.5, open source AMD Vulkan driver) |

### Software

| Component | Version |
|---|---|
| OS | Ubuntu (latest LTS) |
| Kernel | 6.17.0-23-generic |
| Desktop | GNOME on Wayland |
| Display Server | Wayland (XWayland available as fallback) |
| Lutris | 0.5.22 (installed as Flatpak) |
| Wine/Proton | GE-Proton10-34 |
| Mesa | 26.0.5 |
| Vulkan | 1.4.321 |
| OpenGL | 4.6 Core Profile |

### Key Feature Support

| Feature | Status |
|---|---|
| Vulkan | ✅ Supported |
| Esync | ✅ Supported |
| Fsync | ✅ Supported |
| Gamemode | ✅ Supported |
| Gamescope | ❌ Not available |
| MangoHud | ❌ Not installed |
| Steam | ✅ Installed (as Snap — important caveat, see troubleshooting) |
| Lutris | ✅ Installed as Flatpak |

> **⚠️ Important:** Steam is installed as a **Snap** and Lutris as a **Flatpak**. These run in isolated sandboxes and **cannot share libraries with each other**. This has significant implications covered in the troubleshooting section.

---

## 2. Prerequisites — What to Install First

Before configuring Lutris, ensure the following are installed and working on your system.

### 2.1 Lutris (Flatpak — Recommended)

```bash
flatpak install flathub net.lutris.Lutris
```

### 2.2 ProtonUp-Qt — Manage GE-Proton Versions

This is the standard tool for installing and managing GE-Proton builds inside Lutris. **Do not skip this — it is essential for fixing compatibility issues.**

```bash
flatpak install flathub net.davidotek.pupgui2
```

To run it:
```bash
flatpak run net.davidotek.pupgui2
```

> **Critical:** When ProtonUp-Qt opens, click the **"Install for:"** dropdown and select **"Lutris Flatpak"** — not "Steam Snap". If you install to the wrong target, the versions won't appear in Lutris.

### 2.3 Winetricks (System-Level)

Winetricks is used to install Windows runtime libraries into your Wine prefix.

```bash
sudo apt install winetricks
```

### 2.4 Vulkan Tools (Optional but useful for debugging)

```bash
sudo apt install vulkan-tools
```

---

## 3. Lutris Game Configuration

This section covers every setting tab in Lutris for this game. Use it as a reference when setting up from scratch.

### 3.1 Game Options Tab

| Setting | Value |
|---|---|
| Executable | `/path/to/your/game/Expedition33_Steam.exe` |
| Wine prefix | `/home/USERNAME/.wine-expedition33` *(use a dedicated prefix — see section 6)* |
| Working directory | *(leave blank, auto-detected)* |
| Arguments | *(leave blank)* |

> **Why a dedicated prefix?** Using the default `~/.wine` prefix causes conflicts if it was previously used with a different Wine version. A dedicated prefix per game avoids version mismatch crashes entirely.

### 3.2 Runner Options Tab

| Setting | Value | Notes |
|---|---|---|
| Wine version | `GE-Proton10-34` | Install via ProtonUp-Qt |
| Use system winetricks | ON | Recommended |
| Enable DXVK | ON | Required for D3D translation |
| Enable D3D Extras | ON | Additional D3D compatibility |
| D3D Extras version | `v2 (default)` | |
| Enable Esync | ON | Reduces CPU overhead for sync objects |
| Enable Fsync | ON | Better than Esync if kernel supports it |
| Enable AMD FSR | ON | Upscaling support |
| Audio driver | `PulseAudio` | Or `Auto` — see audio section |
| **Graphics driver** | **`Wayland`** | **Not X11 — critical for Wayland sessions** |
| Enable BattlEye Anti-Cheat | OFF | Not needed, can cause issues |
| Enable Easy Anti-Cheat | OFF | Not needed, can cause issues |

> **⚠️ Graphics driver is critical.** If your session is Wayland (`echo $XDG_SESSION_TYPE` returns `wayland`), you must set the graphics driver to **Wayland**, not X11. Using X11 on a Wayland session forces everything through XWayland, adding latency and causing micro-stutters.

### 3.3 System Options Tab

| Setting | Value | Notes |
|---|---|---|
| Disable Lutris Runtime | OFF | Leave enabled, especially in Flatpak |
| Prefer system libraries | OFF | Can conflict with Flatpak sandbox |
| GPU | Auto | |
| Prevent sleep | ON | Stops system from sleeping mid-game |
| Gamescope | N/A | Not available on this system |

---

## 4. Environment Variables — Full Reference

These are set in Lutris → Game → Configure → System Options → Environment Variables.

### 4.1 Final Working Variables

| Key | Value | Purpose |
|---|---|---|
| `GAMEID` | `umu-2679460` | Identifies game to protonfixes (Steam App ID) |
| `SteamAppId` | `2679460` | Required by GE-Proton for game detection |
| `SteamGameId` | `2679460` | Required by GE-Proton for game detection |
| `DXVK_CONFIG` | `dxvk.tearFree = True` | Prevents screen tearing without VSync overhead |
| `PULSE_LATENCY_MSEC` | `30` | Reduces audio latency (lower = less lag, try 30–60) |
| `DXVK_ASYNC` | `1` | Background shader compilation, reduces hitching |
| `vblank_mode` | `0` | Disables driver-level VSync |

### 4.2 Variables to Remove / Avoid

| Key | Reason to Remove |
|---|---|
| `KWIN_COMPOSE` | KDE/KWin only — has zero effect on GNOME |
| `VKD3D_CONFIG=async` | Can cause pipeline stalls in UE5 DX12 games |
| `PROTON_DISABLE_AV1` | Only relevant for Proton Experimental, not GE-Proton |
| `PROTON_USE_WINED3D` | Only relevant for Proton Experimental, not GE-Proton |

### 4.3 Variable Format Notes

- Each variable must be on its **own row** in Lutris — not combined
- `DXVK_CONFIG` uses a single space on each side of `=`: `dxvk.tearFree = True` *(double spaces break it)*
- `GAMEID` must include the `umu-` prefix: `umu-2679460` not just `2679460`

---

## 5. Essential First-Time Setup Steps

Follow these steps in order when setting up the game for the first time.

### Step 1 — Install ProtonUp-Qt and GE-Proton

```bash
flatpak install flathub net.davidotek.pupgui2
flatpak run net.davidotek.pupgui2
```

In ProtonUp-Qt: select **Lutris Flatpak** → Add version → GE-Proton → latest version → Install.

### Step 2 — Create the Game Entry in Lutris

Add game manually → Wine runner → point executable to your game's `.exe` file.

### Step 3 — Configure All Settings

Follow sections 3 and 4 above exactly. Pay special attention to:
- Wine prefix path (dedicated, not `~/.wine`)
- Graphics driver set to Wayland
- All three GAMEID variables set correctly

### Step 4 — Install Visual C++ Runtime

Before launching, install the required Visual C++ runtime into your Wine prefix:

```bash
WINEPREFIX=/home/USERNAME/.wine-expedition33 winetricks vcrun2022
```

This installs Microsoft Visual C++ 2015–2022 redistributables. Without this, the game will show an error dialog and refuse to start.

### Step 5 — First Launch

Launch the game. Expect:
- **First 10–20 minutes:** Random hitching and audio stutter — this is shader compilation building the cache. It is normal and temporary.
- **Session 2 onward:** Significantly smoother
- **Session 4–5:** Cache mostly complete, minimal hitching

---

## 6. Troubleshooting — Issues Encountered & Solutions

This section documents every issue encountered during setup in the order they appeared, including what was tried, what failed, and what ultimately worked.

---

### Issue 1: Horrendous Periodic FPS Drops Every 1–2 Seconds

**Symptoms:**
- FPS crashing to 1–10fps every 1–2 seconds like clockwork
- Audio cutting out at the same moment as the visual freeze
- Game otherwise running at acceptable framerate between drops
- Pattern is rhythmic and perfectly regular — not random

**Root Cause — Identified from Log:**

The log showed a triple pattern firing repeatedly:

```
017c:fixme:vulkan:NtGdiDdDDIOpenResourceFromNtHandle params 0x8dcece0 stub!
017c:fixme:vulkan:NtGdiDdDDIOpenResourceFromNtHandle params 0x8dcece0 stub!
017c:fixme:vulkan:NtGdiDdDDIOpenResourceFromNtHandle params 0x8dcece0 stub!
→ approx 5.93fps  ← immediate crash
→ approx 57.30fps ← recovery
```

Every single FPS crash in the log was immediately preceded by this stub firing in triplets. `NtGdiDdDDIOpenResourceFromNtHandle` is an unimplemented Wine stub for cross-process Vulkan resource sharing — a DXGI feature the game uses for async operations. Each call stalls the render pipeline briefly.

Additionally, the log showed:
```
ProtonFixes: Game title not found in CSV
ProtonFixes: Non-steam game UNKNOWN (umu-default)
```

The game had no GAMEID set, so GE-Proton didn't know what game it was running and applied zero game-specific fixes. The default `GAMEID=umu-default` is a placeholder that bypasses all protonfixes.

Secondary causes:
- Graphics driver set to X11 on a Wayland session → XWayland overhead adding latency
- `KWIN_COMPOSE=0` set (has no effect on GNOME, KDE-only variable)
- `VKD3D_CONFIG=async` potentially causing DX12 pipeline stalls

**What Was Tried:**

1. ✅ Added `GAMEID=umu-2679460`, `SteamAppId=2679460`, `SteamGameId=2679460` to environment variables
2. ✅ Switched graphics driver from X11 to Wayland in Runner options
3. ✅ Removed `KWIN_COMPOSE=0`
4. ✅ Removed `VKD3D_CONFIG=async`

**Result:** The periodic drops were **completely eliminated**. FPS stabilised at a consistent 59–60fps with no rhythmic crashes. The `NtGdiDdDDIOpenResourceFromNtHandle` stubs disappeared entirely from subsequent logs.

**Why It Worked:**

Setting the correct GAMEID allowed protonfixes to identify the game and apply Clair Obscur-specific compatibility patches, which include workarounds for the cross-process Vulkan sharing issue. Switching to the Wayland graphics driver eliminated the XWayland translation layer overhead.

---

### Issue 2: mfplat.dll Crash — MFGetConfigurationDWORD

**Symptoms:**
- Game runs at stable 60fps for 1–2 minutes
- Then crashes abruptly with no on-screen error
- Log shows: `wine: Call from 00006FFFFFBCD1F7 to unimplemented function mfplat.dll.MFGetConfigurationDWORD, aborting`
- Process exits cleanly (return code 0) but game is gone

**Root Cause:**

`MFGetConfigurationDWORD` is a Windows Media Foundation function added in Windows 8. Wine and GE-Proton10-34's `mfplat.dll` implementation does not include this function. The game's audio/video engine calls it during initialization — not during a cutscene, but during engine startup itself — so skipping videos does not help.

**What Was Tried (and Why It Failed):**

1. ❌ **`winetricks mf`** — Installed a native Windows 7 `mf.dll`. This made things worse because the Win7 mf.dll called `MFGetConfigurationDWORD` from mfplat, which still didn't have the function. Winetricks `mf` installs `mf.dll` only — not `mfplat.dll`, which is a completely separate DLL.

2. ❌ **`-nomovies` launch argument** — Standard UE5 argument to skip intro videos. Did not help because the crash happens during Media Foundation engine initialization, not during video playback.

3. ❌ **`PROTON_DISABLE_AV1=1`** — Prevents AV1 codec routing. No effect on this specific crash.

4. ❌ **`PROTON_USE_WINED3D=0`** — Irrelevant to mfplat. No effect.

5. ❌ **`winetricks win10`** — Setting Wine prefix to Windows 10 compatibility. Did not expose the missing function.

6. ❌ **Proton Experimental** — Valve's own Proton build with more complete mfplat. Failed because Steam is installed as a Snap and Lutris as a Flatpak — they are completely sandboxed from each other and cannot share `steamclient.so`. Error: `unable to load native steamclient library`.

7. ❌ **GE-Proton9-27** — Attempted downgrade to an older GE-Proton with a different mfplat implementation. Failed because the Wine prefix was built with GE-Proton10-34 (Wine 11.0) and Wine prefixes **cannot be downgraded** — only upgraded. Result: `Prefix has an invalid version` error, Vulkan driver failed to load entirely.

**What Actually Fixed It:**

The contaminated `~/.wine` prefix (which had been through multiple Wine versions, winetricks installs, and failed experiments) was abandoned entirely. A **fresh dedicated Wine prefix** was created:

In Lutris → Game → Configure → Game options → Wine prefix:
```
/home/USERNAME/.wine-expedition33
```

With a clean prefix using GE-Proton10-34, the mfplat crash did not occur. The game launched successfully and ran at 70–117fps.

**Why the Fresh Prefix Worked:**

The old prefix had accumulated several layers of damage:
- Native `mf.dll` installed by winetricks that conflicted with GE-Proton's own implementation
- Registry entries pointing to wrong DLL versions
- Prefix version metadata from Wine 11.0 that confused older Proton builds
- Various other winetricks-installed components that interfered

A clean prefix gave GE-Proton a blank slate to set up exactly the environment it expects.

**Lesson:** When a Wine prefix has been through major version changes or multiple winetricks installs, creating a fresh dedicated prefix is faster and safer than trying to repair it.

---

### Issue 3: Proton Experimental Fails — steamclient Not Found

**Symptoms:**
- Switched to "Proton - Experimental" in Lutris Wine version dropdown
- Game fails immediately with:
```
0024:err:steamclient:steamclient_init unable to load native steamclient library
0024:err:msvcrt:_wassert ... steamclient_main.c
The explorer process failed to start.
```

**Root Cause:**

Proton Experimental is Valve's Proton build designed to run inside the Steam runtime. It requires `steamclient.so` from a running Steam installation. When launched from Lutris as a Flatpak, it cannot find Steam's libraries because:

- Steam is installed as a **Snap** (isolated sandbox at `/snap/steam/`)
- Lutris is installed as a **Flatpak** (isolated sandbox at `/var/app/net.lutris.Lutris/`)
- Flatpak and Snap sandboxes **cannot see each other's files**
- Even with Steam running in the background, the library is invisible across sandbox boundaries

**What Was Tried:**

1. ❌ Running Steam in the background before launching — made no difference due to sandbox isolation
2. ❌ Considered installing Flatpak Steam alongside Snap Steam — dismissed as overly complex with no guarantee of working

**Resolution:**

Proton Experimental was abandoned. GE-Proton (installed via ProtonUp-Qt into Lutris Flatpak) is the correct tool for this setup because it is self-contained and does not require Steam to be running.

**Important Note for Similar Setups:**

If you have Steam as a Snap and Lutris as a Flatpak, **Proton Experimental will never work** via Lutris. Use GE-Proton exclusively.

---

### Issue 4: GE-Proton Version Downgrade Breaks the Prefix

**Symptoms:**
- Switched Wine version from GE-Proton10-34 to GE-Proton9-27
- Game fails immediately with:
```
Proton: Prefix has an invalid version?! You may want to back up user files and delete this prefix.
Failed to load Wine graphics driver supporting Vulkan.
DxvkInstance: Required instance extensions not supported
```

**Root Cause:**

Wine prefixes store internal version metadata. A prefix built with GE-Proton10-34 (based on Wine 11.0) records that version in its configuration. When GE-Proton9-27 (based on Wine 9.0) tries to use that prefix, it detects a version mismatch.

**Wine prefixes can only be upgraded, never downgraded.** Attempting a downgrade causes:
- The graphics driver to fail to load
- Vulkan/DXVK to fail to initialize
- The game to not even reach the loading screen

**Resolution:**

Do not attempt to downgrade a Wine prefix. If you need to test an older Proton version, always create a **new separate prefix** for that test. The existing prefix must be used only with the same or newer Wine version it was originally built with.

---

### Issue 5: Visual C++ Runtime Error on First Launch

**Symptoms:**
- On first launch with fresh Wine prefix, a Windows error dialog appears:
```
Error
The following component(s) are required to run this program:
Microsoft Visual C++ Runtime
```
- Game does not start

**Root Cause:**

A fresh Wine prefix contains only Wine's own DLLs. It does not include Microsoft's Visual C++ Runtime redistributables (msvcp, vcruntime, etc.) which modern games built with Visual Studio require. Clair Obscur: Expedition 33 is built with Unreal Engine 5 using MSVC, so it requires these.

**Fix:**

```bash
WINEPREFIX=/home/USERNAME/.wine-expedition33 winetricks vcrun2022
```

`vcrun2022` installs the Microsoft Visual C++ 2015–2022 redistributable package which covers all MSVC runtime versions from 2015 through 2022. This is a one-time install per prefix.

**Result:** Game launched successfully after this install.

**Note:** This step should be done as part of initial setup on every fresh prefix before the first launch.

---

### Issue 6: Audio Stutter and Visual Hitching

**Symptoms:**
- Irregular FPS drops of varying severity during gameplay
- Audio cuts out at the exact same moment as visual hitches
- Pattern is random, not rhythmic (unlike Issue 1)
- Gets progressively better the longer you play
- Nearly absent by the 3rd or 4th play session

**Root Cause:**

This is **shader compilation hitching** — a normal and expected behaviour for any DXVK/VKD3D game on its first few sessions.

When DXVK (which translates Direct3D to Vulkan) encounters a shader it has never compiled before, it must pause to compile it on the fly. This compilation happens on the CPU and briefly steals resources from the main game thread, causing the frame time to spike. Since audio is also CPU-bound, the same spike interrupts the audio buffer, causing the cut-out.

This has nothing to do with hardware capability — it happens regardless of how powerful your GPU is, because the bottleneck is the one-time compilation work.

**Why a Fresh Prefix Makes It Worse Initially:**

A fresh Wine prefix has an empty shader cache. Every shader the game uses must be compiled from scratch. The cache is stored at:
```
~/.wine-expedition33/shadercache/
```

As you play, the cache fills up. Shaders only need to be compiled once — subsequent frames using the same shader are instant.

**Fix:**

Add to environment variables in Lutris:

| Key | Value |
|---|---|
| `DXVK_ASYNC` | `1` |

`DXVK_ASYNC=1` allows DXVK to compile shaders on background threads rather than blocking the main render thread. This doesn't eliminate the compilation work — it just moves it off the critical path so the game keeps rendering (at potentially lower quality temporarily) while the shader compiles in the background. The result is much less severe hitching.

**Timeline:**
- Session 1: Frequent hitching throughout, especially in new areas
- Session 2: Noticeably better, hitching mainly in new areas
- Session 3–4: Mostly smooth, occasional hitch on never-before-seen effects
- Session 5+: Essentially gone in areas you've visited

**For Persistent Audio Latency (Non-Stutter):**

If audio feels constantly delayed rather than stuttering, adjust PulseAudio latency:

| Key | Value |
|---|---|
| `PULSE_LATENCY_MSEC` | `30` |

Try values between 20–60ms. Lower values reduce delay but may cause crackling if too low for your system.

---

## 7. How to Read Lutris Logs

Understanding the log format helps diagnose new issues faster.

### 7.1 Getting the Right Log

There are **two different logs** in Lutris — they are not interchangeable:

**The Lutris application log** — This is the Lutris UI's own output. It contains Python errors about the interface (like cursor errors on Wayland) and high-level game start/stop events. It does **not** contain Wine output or game errors. This is what appears in the Lutris "Show logs" window and the Lutris crash reporter.

**The game/Wine log** — This is the actual Wine process output, containing DXVK messages, FPS traces, Wine fixme/err messages, and crash details. This is what you need for game troubleshooting. Find it at:
```bash
ls -lt ~/.cache/lutris/logs/
cat ~/.cache/lutris/logs/MOST_RECENT.log
```

### 7.2 Key Log Patterns

**FPS trace lines** — These appear every few seconds and show real-time performance:
```
0224:trace:fps:win32u_vkQueuePresentKHR 0x55555ac897c8 @ approx 59.48fps, total 53.51fps
```
The first number is the recent framerate, the second is the running average since launch.

**Wine fixme** — Unimplemented stubs, usually harmless:
```
0164:fixme:system:NtUserSystemParametersInfo Unimplemented action: 59
```

**Wine err** — Errors, often significant:
```
018c:err:vulkan:init_vulkan Failed to load Wine graphics driver supporting Vulkan.
```

**Critical crash pattern:**
```
wine: Call from XXXXXXXXXXXXXXXX to unimplemented function DLLNAME.FUNCTIONNAME, aborting
```
This means Wine called a DLL function that doesn't exist in its implementation. The game aborts immediately. The DLL and function name tell you exactly what's missing.

**The stutter pattern** (from this game's original issue):
```
fixme:vulkan:NtGdiDdDDIOpenResourceFromNtHandle params XXXXXXX stub!
fixme:vulkan:NtGdiDdDDIOpenResourceFromNtHandle params XXXXXXX stub!
fixme:vulkan:NtGdiDdDDIOpenResourceFromNtHandle params XXXXXXX stub!
→ approx 5.93fps  ← FPS crash immediately follows
→ approx 57.30fps ← recovery
```
A stub firing immediately before an FPS crash is a direct causal relationship.

### 7.3 Protonfixes Status

Look for these lines early in the log to verify game detection is working:
```
ProtonFixes: Running protonfixes on "GE-Proton10-34"
ProtonFixes: Non-steam game UNKNOWN (umu-2679460)   ← good, ID is recognised
ProtonFixes: Using global defaults for UNKNOWN (umu-2679460)
```

If you see `umu-default` instead of your game's ID, the GAMEID environment variable is not set correctly.

---

## 8. Managing Wine/Proton Versions with ProtonUp-Qt

ProtonUp-Qt is how you install, update, and remove GE-Proton and other compatibility tools for Lutris.

### 8.1 Installing a New GE-Proton Version

```bash
flatpak run net.davidotek.pupgui2
```

1. In the **"Install for:"** dropdown — select **"Lutris Flatpak"**
2. Click **Add version**
3. Compatibility tool: **GE-Proton**
4. Select the version you want
5. Click **Install**

The version will automatically appear in Lutris → Runner options → Wine version dropdown after installation.

### 8.2 Choosing the Right Version

- **Latest GE-Proton** — Best for most games, most up-to-date patches
- **Older GE-Proton** — Sometimes needed if a newer version broke something (but remember: you cannot downgrade an existing prefix — you must create a new one)
- **Proton Experimental** — Valve's own build, requires Steam running, does not work with Snap Steam + Flatpak Lutris

### 8.3 Where Versions Are Installed

GE-Proton versions installed for Lutris Flatpak are stored at:
```
~/.var/app/net.lutris.Lutris/data/lutris/runners/wine/
```

### 8.4 Manual Installation (Alternative)

If ProtonUp-Qt is unavailable, install GE-Proton manually:

```bash
mkdir -p ~/.local/share/Steam/compatibilitytools.d
cd /tmp
wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-ProtonX-XX/GE-ProtonX-XX.tar.gz
tar -xzf GE-ProtonX-XX.tar.gz -C ~/.local/share/Steam/compatibilitytools.d/
```

Replace `X-XX` with the version number. Restart Lutris afterwards.

---

## 9. Final Working Configuration Summary

This is the complete configuration that resulted in the game running at 70–117fps with stable audio after the shader cache was built.

### Environment Variables

| Key | Value |
|---|---|
| `GAMEID` | `umu-2679460` |
| `SteamAppId` | `2679460` |
| `SteamGameId` | `2679460` |
| `DXVK_CONFIG` | `dxvk.tearFree = True` |
| `PULSE_LATENCY_MSEC` | `30` |
| `DXVK_ASYNC` | `1` |
| `vblank_mode` | `0` |

### Runner Options

| Setting | Value |
|---|---|
| Wine version | GE-Proton10-34 |
| Use system winetricks | ON |
| Enable DXVK | ON |
| Enable D3D Extras | ON |
| D3D Extras version | v2 (default) |
| Enable Esync | ON |
| Enable Fsync | ON |
| Enable AMD FSR | ON |
| Audio driver | PulseAudio |
| Graphics driver | **Wayland** |

### System Options

| Setting | Value |
|---|---|
| Disable Lutris Runtime | OFF |
| Prefer system libraries | OFF |
| GPU | Auto |
| Prevent sleep | ON |

### Wine Prefix

```
/home/USERNAME/.wine-expedition33
```

### Post-Install Winetricks Commands (run once per prefix)

```bash
WINEPREFIX=/home/USERNAME/.wine-expedition33 winetricks vcrun2022
```

### Performance Results

| Session | Approximate FPS | Hitching |
|---|---|---|
| Session 1 (first run) | 60–117fps | Frequent at start, reduces over time |
| Session 2 | 70–120fps | Occasional, mainly in new areas |
| Session 3+ | 75–120fps | Minimal |

---

## 10. Glossary

**DXVK** — A Vulkan-based translation layer that converts Direct3D 9/10/11 calls to Vulkan. Allows Windows DX games to run on Linux GPU drivers. Comes bundled with GE-Proton.

**VKD3D** — Similar to DXVK but for Direct3D 12. Clair Obscur uses DX12, so VKD3D handles the main rendering translation.

**Wine** — Software that translates Windows system calls to Linux equivalents, allowing Windows applications to run on Linux without a virtual machine.

**GE-Proton** — A community-maintained fork of Valve's Proton, with additional patches and fixes not yet in the official build. Named after GloriousEggroll, its maintainer.

**Wine Prefix** — A self-contained fake Windows installation directory that Wine uses to store the C: drive, registry, DLLs, and configuration for a Windows application. Each game should ideally have its own prefix.

**mfplat.dll** — Windows Media Foundation Platform DLL. Handles audio/video pipeline initialization. Poorly implemented in Wine — several functions are stubs that cause crashes in UE5 games.

**Shader Compilation / Shader Cache** — GPU programs (shaders) must be compiled for your specific GPU driver before they can run. DXVK compiles these on first use and caches them. Empty cache = compile everything from scratch = hitching on first sessions.

**Protonfixes** — A database of game-specific compatibility patches applied automatically by GE-Proton when it recognises a game by its Steam App ID. Requires GAMEID to be set correctly.

**UMU / umu-launcher** — A launcher layer used by Lutris to run GE-Proton with proper Steam runtime container support, without requiring Steam to be running.

**Esync / Fsync** — Kernel synchronization mechanisms that reduce CPU overhead from Windows synchronization objects (mutexes, events, etc.). Fsync is newer and preferred when available.

**XWayland** — A compatibility layer that allows X11 applications to run inside a Wayland compositor session. Adds overhead compared to native Wayland. Use native Wayland graphics driver when available.

**Flatpak / Snap** — Linux application sandboxing formats. They isolate applications in containers. Flatpak and Snap containers cannot see each other's files — critical to understand when combining Lutris (Flatpak) and Steam (Snap).

---

*Guide produced from a real troubleshooting session. All issues, failed attempts, and working solutions are documented from actual logs.*
