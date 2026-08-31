# 🖥️ Linux Display Brightness Guide

A practical reference for controlling monitor brightness across different Linux setups.

---

## 1. Figure Out Your Setup First

Before picking a tool, run this to check your display server:

```bash
echo $XDG_SESSION_TYPE
```

| Output | Meaning |
|--------|---------|
| `x11` | Running X11 — most tools work |
| `wayland` | Running Wayland — some tools won't work |

Also check what monitors are connected:

```bash
xrandr --listmonitors
```

---

## 2. Choose the Right Tool

| Setup | Best Tool |
|-------|-----------|
| Laptop internal screen (X11) | `brightnessctl` or `xbacklight` |
| Laptop internal screen (Wayland) | `brightnessctl` |
| External monitor (DDC/CI supported) | `ddcutil` |
| Want a GUI | `Brightness Controller` |

> **Tip:** Most modern external monitors support DDC/CI. Check your monitor's OSD menu to confirm it's enabled.

---

## 3. Tool Reference

### `ddcutil` — Best for External Monitors

Communicates with your monitor's built-in Virtual Control Panel (VCP) over the DDC protocol.

**Install:**
```bash
sudo apt install ddcutil
```

**Skip sudo every time (recommended):**
```bash
sudo usermod -aG i2c $USER
# Log out and back in after running this
```

**Detect connected monitors:**
```bash
ddcutil detect
```

**Get current brightness:**
```bash
ddcutil getvcp 10               # all monitors
ddcutil getvcp 10 --display 1   # specific monitor
```

**Set brightness (0–100):**
```bash
ddcutil setvcp 10 70            # all monitors
ddcutil setvcp 10 70 --display 1  # specific monitor
```

**Command breakdown:**
> `ddcutil setvcp 10 70 --display 1`
> = *"Set Virtual Control Panel — button 10 (brightness) — to 70 — on display 1"*

**Common VCP codes:**

| Code | Feature |
|------|---------|
| `10` | Brightness |
| `12` | Contrast |
| `62` | Audio volume |
| `60` | Input source |

**See all supported settings for a monitor:**
```bash
ddcutil capabilities --display 1
```

---

### `brightnessctl` — Best for Laptop Screens

Controls the hardware backlight directly. Works on both X11 and Wayland.

**Install:**
```bash
sudo apt install brightnessctl
```

**Get current brightness:**
```bash
brightnessctl get
```

**Set brightness:**
```bash
brightnessctl set 70%    # set to 70%
brightnessctl set +10%   # increase by 10%
brightnessctl set 10%-   # decrease by 10%
```

---

### `xbacklight` — Alternative for X11 Laptops

Older tool, X11 only. May not work on all systems.

**Install:**
```bash
sudo apt install xbacklight
```

**Usage:**
```bash
xbacklight -set 70     # set to 70%
xbacklight -inc 10     # increase by 10%
xbacklight -dec 10     # decrease by 10%
xbacklight -get        # get current value
```

---

### `xrandr` — Software Brightness (X11 Only)

Does not change real hardware brightness — applies a software filter instead. Works without any special hardware support.

**List displays:**
```bash
xrandr --listmonitors
```

**Set brightness (0.0 – 1.0 scale):**
```bash
xrandr --output HDMI-1 --brightness 0.7
xrandr --output eDP-1 --brightness 0.8   # typical laptop screen name
```

> ⚠️ This is a software-only adjustment. It won't save power like real hardware brightness control.

---

## 4. Bind to Keyboard Shortcuts

For quick day-to-day use, bind brightness commands to hotkeys in your desktop environment.

**GNOME (Settings → Keyboard → Custom Shortcuts):**
- Name: `Brightness Up`
- Command: `ddcutil setvcp 10 80 --display 1`
- Assign a key combo (e.g. `Super + F6`)

**KDE (System Settings → Shortcuts → Custom Shortcuts):**
- Same idea — point to your preferred command.

---

## 5. Troubleshooting

| Problem | Fix |
|---------|-----|
| `ddcutil detect` finds nothing | Enable DDC/CI in your monitor's OSD menu |
| Permission denied without sudo | Run `sudo usermod -aG i2c $USER` and re-login |
| `xbacklight` has no output | Try `brightnessctl` instead |
| Brightness Controller GUI doesn't work | Check if on Wayland — switch to X11 session at login |
| `xrandr` brightness not applying | Confirm you're on X11, not Wayland |

---

## 6. Quick Reference Card

```bash
# Detect monitors (ddcutil)
ddcutil detect

# Get brightness
ddcutil getvcp 10 --display 1
brightnessctl get

# Set brightness
ddcutil setvcp 10 70 --display 1
brightnessctl set 70%
xrandr --output HDMI-1 --brightness 0.7

# Adjust relatively
brightnessctl set +10%
brightnessctl set 10%-
```

---

*Tested on Ubuntu. Most commands apply to other Debian-based distros. For Arch/Fedora, replace `apt install` with `pacman -S` or `dnf install` accordingly.*
