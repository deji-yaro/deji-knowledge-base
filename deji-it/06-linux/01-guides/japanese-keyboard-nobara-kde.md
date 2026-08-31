# How to Enable Japanese Input on Nobara (KDE Plasma)

This guide walks through installing Fcitx5 with Mozc to get proper hiragana/katakana/kanji conversion on Nobara OS with KDE Plasma.

> Note: This is different from adding a "Japanese" physical keyboard layout in System Settings — that only remaps your physical keys (JIS layout) and does **not** give you hiragana/kanji conversion. You need an input method framework (Fcitx5) plus a Japanese input engine (Mozc) for that.

## 1. Install the required packages

Open a terminal and run:

```bash
sudo dnf install fcitx5 fcitx5-mozc fcitx5-configtool fcitx5-qt fcitx5-gtk fcitx5-kcm
```

- **fcitx5** – the input method framework
- **fcitx5-mozc** – the Japanese conversion engine (romaji → hiragana/katakana/kanji)
- **fcitx5-configtool** – GUI to configure input methods
- **fcitx5-qt / fcitx5-gtk** – integration so Qt/KDE and GTK apps both work with it
- **fcitx5-kcm** – adds Fcitx5 integration into KDE System Settings (may not always show up even when installed)

## 2. Set environment variables

KDE doesn't always wire this up automatically, so set it manually. Run:

```bash
mkdir -p ~/.config/plasma-workspace/env
cat << 'EOF' > ~/.config/plasma-workspace/env/im.sh
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
EOF
```

## 3. Log out and back in

This ensures the Fcitx5 daemon and the environment variables both load together in your new session.

## 4. Add Mozc as an input method

Open the **Fcitx5 Configuration** app (search for it in the app launcher, or run `fcitx5-configtool` in a terminal).

1. Go to the **Input Method** tab
2. Uncheck **"Only Show Current Language"** (this is important — Mozc is hidden otherwise)
3. In the **Search Input Method** box, type `mozc`
4. Select **Mozc** and click the **left arrow (`<`)** to add it to your "Current Input Method" list
5. Make sure the order is:
   - Keyboard - English (US) *(first)*
   - Mozc *(second)*
6. Click **Apply**, then **OK**

## 5. Check your toggle shortcut

Still in Fcitx5 Configuration, go to the **Global Options** tab and confirm the **"Trigger Input Method"** shortcut (commonly `Ctrl+Space`). This is the key combo that switches between English and Mozc.

## 6. Switch Mozc into Hiragana mode

Once Fcitx5 is running, you'll see a tray icon. When Mozc is active:

- Click the tray icon to open its mode menu
- Choose **あ Hiragana** (not "A" direct input, which just types plain letters)

## 7. Test it

Click into any text field (browser address bar, Kate, etc.), toggle to Mozc with your shortcut, confirm Hiragana mode is selected, then type:

```
aiueo
```

It should convert live to **あいうえお**. Typing romaji and hitting Space/Enter also lets you convert to katakana or kanji.

## Troubleshooting

| Problem | Fix |
|---|---|
| No "Input Method" panel in System Settings | Not required — just use `fcitx5-configtool` directly instead |
| Mozc doesn't appear in the search list | Make sure "Only Show Current Language" is unchecked |
| Typing still shows plain romaji, not hiragana | Click the tray icon and make sure mode is set to **あ Hiragana**, not "A" direct input |
| Toggle shortcut doesn't do anything | Check/set it under Global Options → Trigger Input Method |
| Nothing happens after installing | Fully log out and back in — don't just lock/unlock |
