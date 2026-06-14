# UCanCustom — Tokyo Night Terminal Rice

A beautiful, idempotent terminal setup script for **macOS** and **Arch Linux**.

Transforms your shell into an r/unixporn-style "rice" with:
- **starship** — elegant, modular prompt  
- **fastfetch** — minimalist system info
- **eza** — modern `ls` with icons and colors
- **bat** — syntax-highlighted `cat`
- **zoxide** — smart directory jumping
- **fzf** — fuzzy finder for files & history
- **zsh plugins** — autosuggestions + syntax highlighting
- **Tokyo Night theme** — beautiful dark color scheme with Nerd Font icons

## Quick Start

### macOS (Terminal Only)

```bash
bash ./install.sh
```

**Requirements:**
- macOS 10.15+ (Catalina or later)
- zsh (default on modern macOS)

**What it installs:**
- Homebrew packages: starship, fastfetch, eza, bat, zoxide, fzf, zsh plugins
- Ghostty terminal + JetBrainsMono Nerd Font

---

### Arch Linux — Shell Only

For a minimal shell setup (terminal + prompt + tools):

```bash
bash ./install-archlinux.sh
```

**What it installs:**
- CLI tools: starship, fastfetch, eza, bat, zoxide, fzf, zsh plugins
- Terminal: kitty or alacritty (choose during install)
- Fonts + theme configs

---

### Arch Linux — Full Desktop Rice (r/unixporn style) ⭐

For a complete desktop rice with WM, bar, compositor, GTK theme, icons:

```bash
bash ./install-linux-rice-full.sh
```

**Choose your WM/DE:**

| WM | Type | Display | Style | Difficulty |
|-------|---------|---------|--------|----------|
| **dwm** | Minimalist tiling | X11 | Ultra-light, compiled | Hard (needs rebuild) |
| **i3** | Keyboard-driven | X11 | Highly customizable | Easy |
| **bspwm** | Binary space partition | X11 | Modern, powerful | Medium |
| **hyprland** | Modern animated | Wayland | Beautiful, eye candy ✨ | Easy |
| **KDE Plasma** | Full desktop | Any | Feature-rich, beautiful | Easy |

**What it installs:**
- **All shell tools** (starship, fastfetch, eza, bat, zoxide, fzf, zsh plugins)
- **Your chosen WM/DE** with full configs
- **Theme + Icons**:
  - Tokyo Night GTK theme
  - Papirus Dark icons  
  - JetBrainsMono Nerd Font
- **Status bars**: polybar (X11) or waybar (Wayland)
- **Compositor**: picom (X11) or built-in (Wayland)

**Perfect for r/unixporn posting!** 📸

## Features

✅ **Safe & Idempotent**  
→ Re-run anytime. Won't duplicate config blocks or require fresh installs.

✅ **Automatic Backups**  
→ Your original `~/.zshrc` is backed up to `~/.zshrc.backup` on first run.

✅ **No Sudo Needed** (macOS)  
→ Homebrew is user-scoped. macOS setup requires zero privilege elevation.

✅ **Cross-Platform**  
→ Same Tokyo Night theme, colors, and aliases on both macOS and Arch Linux.

✅ **Managed Config Block**  
→ Script uses markers (`# >>> rice setup (managed) >>>`) to ensure idempotency.

## Config Locations

After installation, customize these files:

| File | Purpose |
|------|---------|
| `~/.config/starship.toml` | Prompt styling (two-line powerline) |
| `~/.config/ghostty/config` (macOS) | Terminal emulator settings |
| `~/.config/kitty/kitty.conf` (Arch) | Kitty terminal settings |
| `~/.config/alacritty/alacritty.toml` (Arch) | Alacritty terminal settings |
| `~/.config/fastfetch/config.jsonc` | System info display |
| `~/.config/eza/theme.yml` | File listing colors |
| `~/.config/bat/config` | Syntax highlighting theme |

## Aliases

Installed aliases (in `~/.zshrc`):

```bash
ls    # → eza --icons --group-directories-first
ll    # → eza -lh --icons (with git status)
la    # → eza -lah --icons (all files + git)
lt    # → eza --tree (tree view)
cat   # → bat --paging=never (syntax-highlighted cat)
```

## Post-Install

After running the installer:

1. **Reload shell:** `exec zsh`
2. **First time:** zoxide learns directory shortcuts as you `cd` around (use `z <name>` to jump)
3. **(macOS)** Open Ghostty — theme + font are auto-applied
4. **(Arch)** Your chosen terminal is ready to use

## Troubleshooting

### Icons show as boxes/squares

The NerdFont isn't loaded. Fix:

**macOS:**  
→ Ghostty loads it automatically. If using another terminal, set "JetBrainsMono Nerd Font" in terminal settings.

**Arch:**  
→ Verify font installed: `pacman -Q ttf-jetbrains-mono-nerd`  
→ Set font in terminal settings or DE font preferences.

### zsh plugins not found

**Arch only:**

```bash
sudo pacman -S zsh-autosuggestions zsh-syntax-highlighting
```

### fzf keybindings not working

Re-source fzf in your shell:

```bash
exec zsh
```

Or manually:

```bash
source <(fzf --zsh)
```

## Uninstall

To revert:

1. Restore your original shell config:
   ```bash
   cp ~/.zshrc.backup ~/.zshrc
   ```

2. Uninstall packages:

   **macOS:**
   ```bash
   brew uninstall starship fastfetch eza bat zoxide fzf zsh-autosuggestions zsh-syntax-highlighting ghostty font-jetbrains-mono-nerd-font
   ```

   **Arch:**
   ```bash
   sudo pacman -R starship fastfetch eza bat zoxide fzf zsh zsh-autosuggestions zsh-syntax-highlighting ttf-jetbrains-mono-nerd
   ```

## Color Scheme

Built on the **Tokyo Night** palette:

| Use | Color |
|-----|-------|
| Background | `#1a1b26` (dark blue) |
| Foreground | `#c0caf5` (light lavender) |
| Accent (blue) | `#7aa2f7` |
| Accent (green) | `#9ece6a` |
| Accent (red) | `#f7768e` |
| Accent (yellow) | `#e0af68` |

## Credits

- **Tokyo Night theme:** [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim)
- **Tools:** starship, fastfetch, eza, bat, zoxide, fzf
- **Font:** JetBrains Mono Nerd Font

## License

MIT — Use freely, modify as you like.
