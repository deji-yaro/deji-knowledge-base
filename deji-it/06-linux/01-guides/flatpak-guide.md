# 📦 Flatpak User Guide

A friendly guide to installing, managing, and getting the most out of Flatpak on Linux.

---

## What is Flatpak?

Flatpak is a universal Linux app packaging system. Instead of relying on your distro's repositories, Flatpak lets you install apps that:

- Work on **any distro** (Ubuntu, Fedora, Arch, etc.)
- Get **more frequent updates** directly from developers
- Run in a **sandbox** for better security
- Come with their own dependencies — no more dependency hell

The main app store for Flatpak is **[Flathub](https://flathub.org)** — browse it to find app IDs before installing.

---

## 🚀 Getting Started

### Install Flatpak itself
```bash
sudo apt install flatpak        # Debian/Ubuntu
sudo dnf install flatpak        # Fedora
sudo pacman -S flatpak          # Arch
```

### Add Flathub (the main repository)
```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

> Do this once after installing Flatpak. You won't need to do it again.

---

## 🔍 Finding Apps

### Search from the terminal
```bash
flatpak search firefox
flatpak search lutris
flatpak search spotify
```

The output gives you the **Application ID** (e.g. `org.mozilla.firefox`) — you'll use this for installing.

> Tip: IDs sometimes get truncated in search output (e.g. `…t.lutris.Lutris`). Visit [flathub.org](https://flathub.org) for the full ID if unsure.

---

## 📥 Installing Apps

### Standard install (recommended)
```bash
flatpak install flathub net.lutris.Lutris
flatpak install flathub org.mozilla.firefox
flatpak install flathub com.spotify.Client
flatpak install flathub org.videolan.VLC
flatpak install flathub com.discordapp.Discord
flatpak install flathub net.pcsx2.PCSX2
flatpak install flathub org.prismlauncher.PrismLauncher
```

### Install without sudo (user-only install)
```bash
flatpak install --user flathub org.mozilla.firefox
```

> **System install** = available to all users on the machine (requires sudo)  
> **User install** = only for your account, no sudo needed

---

## ▶️ Running Apps

```bash
flatpak run org.mozilla.firefox
flatpak run net.lutris.Lutris
```

> In practice, your desktop launcher handles this automatically. You'll rarely need to run apps manually from the terminal.

---

## 🔄 Updating Apps

### Update everything
```bash
flatpak update
```

### Update a specific app
```bash
flatpak update net.lutris.Lutris
```

> Most desktop environments handle this automatically in the background.

---

## 📋 Managing Installed Apps

### List all installed Flatpaks (apps + runtimes)
```bash
flatpak list
```

### List only your installed apps (no runtimes clutter)
```bash
flatpak list --app
```

### Uninstall an app
```bash
flatpak uninstall net.lutris.Lutris
```

### Remove unused runtimes (free up space)
```bash
flatpak uninstall --unused
```

### Fix corrupted installs
```bash
flatpak repair
```

---

## 🔒 Permissions & Flatseal

Flatpak sandboxes apps by default — which is great for security, but can cause issues like:

- App can't see your home folder or external drives
- No access to game controllers or webcams
- Audio/video issues
- Problems with custom game/ROM directories

### Fix with Flatseal (recommended)

Install Flatseal — a GUI permission manager for Flatpak:

```bash
flatpak install flathub com.github.tchx84.Flatseal
```

Open it, pick an app, and toggle permissions visually. No terminal commands needed.

**Common permissions you might need to enable:**
- `Home folder` — access to your files
- `All filesystems` — access everywhere (use sparingly)
- `All devices` — controllers, webcams, GPU
- `Network` — internet access

### Fix with terminal (alternative to Flatseal)

```bash
# Grant access to home folder
flatpak override --user --filesystem=home net.lutris.Lutris

# Grant access to a specific folder
flatpak override --user --filesystem=/media/games net.lutris.Lutris

# Grant access to all devices
flatpak override --user --device=all net.pcsx2.PCSX2

# Reset all overrides for an app
flatpak override --user --reset net.lutris.Lutris
```

---

## 📁 Where App Data Lives

Flatpak apps store their configs, saves, and cache here:

```
~/.var/app/<Application-ID>/
```

**Examples:**
```
~/.var/app/net.lutris.Lutris/
~/.var/app/net.pcsx2.PCSX2/
~/.var/app/dev.vencord.Vesktop/
```

> Useful when you need to back up save data, wipe an app's config, or find where a game stored its settings.

---

## 🎮 Gaming-Specific Tips

Since you're running Lutris, PCSX2, and Prism Launcher:

| App | Likely permissions needed |
|-----|--------------------------|
| **Lutris** | Filesystem access to wherever your games are stored |
| **PCSX2** | Access to your BIOS files and ROM directories |
| **Prism Launcher** | Home folder access for modpacks/Java |
| **Vesktop** | Should work out of the box |

Use Flatseal to grant these without touching the terminal.

---

## ⚖️ Flatpak vs System Repos — When to Use Which

| Use Flatpak for | Use system repos for |
|-----------------|----------------------|
| GUI desktop apps | CLI tools (`git`, `curl`, `htop`) |
| Gaming (Lutris, emulators) | System utilities & daemons |
| Apps needing latest versions | Drivers & kernel modules |
| Cross-distro compatibility | Servers & headless environments |

> They complement each other — Flatpak for apps, system repos for plumbing.

---

## 🧹 Quick Reference Cheatsheet

```bash
# Setup
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Find & Install
flatpak search <name>
flatpak install flathub <app-id>

# Run
flatpak run <app-id>

# Update
flatpak update

# List
flatpak list --app

# Uninstall
flatpak uninstall <app-id>
flatpak uninstall --unused

# Permissions (or just use Flatseal)
flatpak override --user --filesystem=home <app-id>
flatpak override --user --reset <app-id>

# Maintenance
flatpak repair
```

---

*Happy Flatpaking! 🐧*
