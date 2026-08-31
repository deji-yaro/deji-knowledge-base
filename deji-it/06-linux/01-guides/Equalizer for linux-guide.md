Ubuntu's default audio stack (PulseAudio or PipeWire) doesn't expose an EQ in the system settings. You need to install a third-party tool.

## Quick options:

### 1. **EasyEffects** (recommended for PipeWire — default on Ubuntu 22.04+)
```bash
sudo apt install easyeffects
```
- System-wide EQ, compression, limiter, and more
- Integrates with PipeWire natively
- Launch it, go to "Effects" → add "Equalizer"
- Save presets per device if needed

### 2. **PulseAudio Equalizer** (if you're still on PulseAudio)
```bash
sudo apt install pulseaudio-equalizer
```
- Older, simpler UI
- Works via LADSPA plugins
- Launch with `qpaeq`

---

## Check which audio server you're running:
```bash
pactl info | grep "Server Name"
```
- `PulseAudio` → use option 2
- `PipeWire` → use option 1 (EasyEffects)

---

## If EasyEffects doesn't show up or detect your jack output:
1. Make sure the correct output device is selected in system settings
2. In EasyEffects, verify the input/output pipeline is active
3. Some hardware requires enabling the analog output explicitly:
   ```bash
   pactl list sinks short
   ```
   Look for your analog/HD-Audio sink and ensure it's not muted.

---

**Note:** EasyEffects only works with PipeWire. If you're on an older Ubuntu still using PulseAudio, stick with `pulseaudio-equalizer` or consider migrating to PipeWire (`sudo apt install pipewire-pulse`).