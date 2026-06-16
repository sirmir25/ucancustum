#!/usr/bin/env bash
# install-linux-rice-full.sh — Complete Tokyo Night rice for Linux (all WMs)
#
# Supports: dwm | i3 | bspwm | hyprland | KDE Plasma
# Full desktop setup: WM + bar + compositor + theme + fonts
#
# Distros: Arch/Manjaro (pacman) · Debian/Ubuntu (apt) ·
#          Fedora/RHEL (dnf) · openSUSE (zypper) · Void Linux (xbps)
#
set -euo pipefail

# ---------- pretty logging ----------
c_blue=$'\033[34m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_red=$'\033[31m'; c_rst=$'\033[0m'
info() { printf "%s==>%s %s\n" "$c_blue" "$c_rst" "$*"; }
ok()   { printf "%s ✓%s %s\n" "$c_grn" "$c_rst" "$*"; }
warn() { printf "%s !%s %s\n" "$c_yel" "$c_rst" "$*"; }
err()  { printf "%s ✗%s %s\n" "$c_red" "$c_rst" "$*" >&2; }

# ---------- sanity check ----------
[[ "$(uname)" == "Linux" ]] || { err "This script targets Linux."; exit 1; }

# ---------- distro / package-manager abstraction ----------
detect_pm() {
  if   command -v pacman       >/dev/null 2>&1; then PM="pacman"
  elif command -v apt-get      >/dev/null 2>&1; then PM="apt"
  elif command -v dnf          >/dev/null 2>&1; then PM="dnf"
  elif command -v zypper       >/dev/null 2>&1; then PM="zypper"
  elif command -v xbps-install >/dev/null 2>&1; then PM="xbps"
  else err "No supported package manager found (pacman/apt/dnf/zypper/xbps)."; exit 1
  fi
  info "Detected package manager: $PM"
}

pm_update() {
  case "$PM" in
    pacman) sudo pacman -Sy ;;
    apt)    sudo apt-get update ;;
    dnf)    sudo dnf check-update || true ;;
    zypper) sudo zypper refresh ;;
    xbps)   sudo xbps-install -Su || true ;;
  esac
}

pkg_install() {
  case "$PM" in
    pacman) sudo pacman -S --noconfirm --needed "$@" ;;
    apt)    sudo apt-get install -y "$@" ;;
    dnf)    sudo dnf install -y "$@" ;;
    zypper) sudo zypper install -y "$@" ;;
    xbps)   sudo xbps-install -y "$@" ;;
  esac
}

pkg_installed() {
  case "$PM" in
    pacman)     pacman -Q "$1"   >/dev/null 2>&1 ;;
    apt)        dpkg -s "$1"     >/dev/null 2>&1 ;;
    dnf|zypper) rpm -q "$1"      >/dev/null 2>&1 ;;
    xbps)       xbps-query "$1"  >/dev/null 2>&1 ;;
  esac
}

distro_pkg() {
  case "$PM:$1" in
    # ---------- shell tools ----------
    pacman:zsh)                     echo "zsh" ;;
    pacman:zsh-autosuggestions)     echo "zsh-autosuggestions" ;;
    pacman:zsh-syntax-highlighting) echo "zsh-syntax-highlighting" ;;
    pacman:nerd-font)               echo "ttf-jetbrains-mono-nerd" ;;
    pacman:firasans)                echo "otf-firasans" ;;
    pacman:noto-emoji)              echo "noto-fonts-emoji" ;;
    pacman:eza)                     echo "eza" ;;
    pacman:bat)                     echo "bat" ;;
    pacman:fzf)                     echo "fzf" ;;
    pacman:zoxide)                  echo "zoxide" ;;
    pacman:fastfetch)               echo "fastfetch" ;;
    pacman:starship)                echo "starship" ;;
    # ---------- terminals ----------
    pacman:kitty)                   echo "kitty" ;;
    pacman:alacritty)               echo "alacritty" ;;
    # ---------- WM/DE core ----------
    pacman:i3)                      echo "i3-wm" ;;
    pacman:i3status)                echo "i3status" ;;
    pacman:polybar)                 echo "polybar" ;;
    pacman:picom)                   echo "picom" ;;
    pacman:sway)                    echo "sway" ;;
    pacman:swaylock)                echo "swaylock" ;;
    pacman:swayidle)                echo "swayidle" ;;
    pacman:waybar)                  echo "waybar" ;;
    pacman:bspwm)                   echo "bspwm" ;;
    pacman:sxhkd)                   echo "sxhkd" ;;
    pacman:hyprland)                echo "hyprland" ;;
    pacman:hyprlock)                echo "hyprlock" ;;
    pacman:hypridle)                echo "hypridle" ;;
    pacman:mako)                    echo "mako" ;;
    pacman:wl-clipboard)            echo "wl-clipboard" ;;
    pacman:dmenu)                   echo "dmenu" ;;
    pacman:dunst)                   echo "dunst" ;;
    pacman:kde)                     echo "plasma-meta" ;;
    # ---------- build deps ----------
    pacman:build-essential)         echo "base-devel" ;;
    pacman:libx11)                  echo "libx11" ;;
    pacman:libxft)                  echo "libxft" ;;
    pacman:libxinerama)             echo "libxinerama" ;;
    # ---------- GTK ----------
    pacman:gtk-engine-murrine)      echo "gtk-engine-murrine" ;;
    pacman:sassc)                   echo "sassc" ;;
    pacman:git)                     echo "git" ;;
    pacman:curl)                    echo "curl" ;;

    # ---------- apt ----------
    apt:zsh)                        echo "zsh" ;;
    apt:zsh-autosuggestions)        echo "zsh-autosuggestions" ;;
    apt:zsh-syntax-highlighting)    echo "zsh-syntax-highlighting" ;;
    apt:nerd-font)                  echo "fonts-jetbrains-mono" ;;
    apt:firasans)                   echo "fonts-firacode" ;;
    apt:noto-emoji)                 echo "fonts-noto-color-emoji" ;;
    apt:eza)                        echo "eza" ;;
    apt:bat)                        echo "bat" ;;
    apt:fzf)                        echo "fzf" ;;
    apt:zoxide)                     echo "" ;;
    apt:fastfetch)                  echo "" ;;
    apt:starship)                   echo "" ;;
    apt:kitty)                      echo "kitty" ;;
    apt:alacritty)                  echo "alacritty" ;;
    apt:i3)                         echo "i3" ;;
    apt:i3status)                   echo "i3status" ;;
    apt:polybar)                    echo "polybar" ;;
    apt:picom)                      echo "picom" ;;
    apt:sway)                       echo "sway" ;;
    apt:swaylock)                   echo "swaylock" ;;
    apt:swayidle)                   echo "swayidle" ;;
    apt:waybar)                     echo "waybar" ;;
    apt:bspwm)                      echo "bspwm" ;;
    apt:sxhkd)                      echo "sxhkd" ;;
    apt:hyprland)                   echo "hyprland" ;;
    apt:hyprlock)                   echo "" ;;
    apt:hypridle)                   echo "" ;;
    apt:mako)                       echo "mako-notifier" ;;
    apt:wl-clipboard)               echo "wl-clipboard" ;;
    apt:dmenu)                      echo "dmenu" ;;
    apt:dunst)                      echo "dunst" ;;
    apt:kde)                        echo "kde-plasma-desktop" ;;
    apt:build-essential)            echo "build-essential" ;;
    apt:libx11)                     echo "libx11-dev" ;;
    apt:libxft)                     echo "libxft-dev" ;;
    apt:libxinerama)                echo "libxinerama-dev" ;;
    apt:gtk-engine-murrine)         echo "gtk2-engines-murrine" ;;
    apt:sassc)                      echo "sassc" ;;
    apt:git)                        echo "git" ;;
    apt:curl)                       echo "curl" ;;

    # ---------- dnf ----------
    dnf:zsh)                        echo "zsh" ;;
    dnf:zsh-autosuggestions)        echo "zsh-autosuggestions" ;;
    dnf:zsh-syntax-highlighting)    echo "zsh-syntax-highlighting" ;;
    dnf:nerd-font)                  echo "jetbrains-mono-fonts" ;;
    dnf:firasans)                   echo "fira-code-fonts" ;;
    dnf:noto-emoji)                 echo "google-noto-emoji-fonts" ;;
    dnf:eza)                        echo "eza" ;;
    dnf:bat)                        echo "bat" ;;
    dnf:fzf)                        echo "fzf" ;;
    dnf:zoxide)                     echo "" ;;
    dnf:fastfetch)                  echo "" ;;
    dnf:starship)                   echo "" ;;
    dnf:kitty)                      echo "kitty" ;;
    dnf:alacritty)                  echo "alacritty" ;;
    dnf:i3)                         echo "i3" ;;
    dnf:i3status)                   echo "i3status" ;;
    dnf:polybar)                    echo "polybar" ;;
    dnf:picom)                      echo "picom" ;;
    dnf:sway)                       echo "sway" ;;
    dnf:swaylock)                   echo "swaylock" ;;
    dnf:swayidle)                   echo "swayidle" ;;
    dnf:waybar)                     echo "waybar" ;;
    dnf:bspwm)                      echo "bspwm" ;;
    dnf:sxhkd)                      echo "sxhkd" ;;
    dnf:hyprland)                   echo "hyprland" ;;
    dnf:hyprlock)                   echo "" ;;
    dnf:hypridle)                   echo "" ;;
    dnf:mako)                       echo "mako" ;;
    dnf:wl-clipboard)               echo "wl-clipboard" ;;
    dnf:dmenu)                      echo "dmenu" ;;
    dnf:dunst)                      echo "dunst" ;;
    dnf:kde)                        echo "plasma-desktop" ;;
    dnf:build-essential)            echo "gcc make" ;;
    dnf:libx11)                     echo "libX11-devel" ;;
    dnf:libxft)                     echo "libXft-devel" ;;
    dnf:libxinerama)                echo "libXinerama-devel" ;;
    dnf:gtk-engine-murrine)         echo "gtk-murrine-engine" ;;
    dnf:sassc)                      echo "sassc" ;;
    dnf:git)                        echo "git" ;;
    dnf:curl)                       echo "curl" ;;

    # ---------- zypper ----------
    zypper:zsh)                     echo "zsh" ;;
    zypper:zsh-autosuggestions)     echo "zsh-autosuggestions" ;;
    zypper:zsh-syntax-highlighting) echo "zsh-syntax-highlighting" ;;
    zypper:nerd-font)               echo "jetbrains-mono-fonts" ;;
    zypper:firasans)                echo "fira-code-fonts" ;;
    zypper:noto-emoji)              echo "noto-coloremoji-fonts" ;;
    zypper:eza)                     echo "eza" ;;
    zypper:bat)                     echo "bat" ;;
    zypper:fzf)                     echo "fzf" ;;
    zypper:zoxide)                  echo "" ;;
    zypper:fastfetch)               echo "" ;;
    zypper:starship)                echo "" ;;
    zypper:kitty)                   echo "kitty" ;;
    zypper:alacritty)               echo "alacritty" ;;
    zypper:i3)                      echo "i3" ;;
    zypper:i3status)                echo "i3status" ;;
    zypper:polybar)                 echo "polybar" ;;
    zypper:picom)                   echo "picom" ;;
    zypper:sway)                    echo "sway" ;;
    zypper:swaylock)                echo "swaylock" ;;
    zypper:swayidle)                echo "swayidle" ;;
    zypper:waybar)                  echo "waybar" ;;
    zypper:bspwm)                   echo "bspwm" ;;
    zypper:sxhkd)                   echo "sxhkd" ;;
    zypper:hyprland)                echo "hyprland" ;;
    zypper:hyprlock)                echo "" ;;
    zypper:hypridle)                echo "" ;;
    zypper:mako)                    echo "mako" ;;
    zypper:wl-clipboard)            echo "wl-clipboard" ;;
    zypper:dmenu)                   echo "dmenu" ;;
    zypper:dunst)                   echo "dunst" ;;
    zypper:kde)                     echo "plasma5-session" ;;
    zypper:build-essential)         echo "gcc make" ;;
    zypper:libx11)                  echo "libX11-devel" ;;
    zypper:libxft)                  echo "libXft-devel" ;;
    zypper:libxinerama)             echo "libXinerama-devel" ;;
    zypper:gtk-engine-murrine)      echo "gtk2-engine-murrine" ;;
    zypper:sassc)                   echo "sassc" ;;
    zypper:git)                     echo "git" ;;
    zypper:curl)                    echo "curl" ;;

    # ---------- xbps ----------
    xbps:zsh)                       echo "zsh" ;;
    xbps:zsh-autosuggestions)       echo "zsh-autosuggestions" ;;
    xbps:zsh-syntax-highlighting)   echo "zsh-syntax-highlighting" ;;
    xbps:nerd-font)                 echo "font-jetbrains-mono-nerd-fonts" ;;
    xbps:firasans)                  echo "font-fira-code" ;;
    xbps:noto-emoji)                echo "noto-fonts-emoji" ;;
    xbps:eza)                       echo "eza" ;;
    xbps:bat)                       echo "bat" ;;
    xbps:fzf)                       echo "fzf" ;;
    xbps:zoxide)                    echo "zoxide" ;;
    xbps:fastfetch)                 echo "fastfetch" ;;
    xbps:starship)                  echo "starship" ;;
    xbps:kitty)                     echo "kitty" ;;
    xbps:alacritty)                 echo "alacritty" ;;
    xbps:i3)                        echo "i3" ;;
    xbps:i3status)                  echo "i3status" ;;
    xbps:polybar)                   echo "polybar" ;;
    xbps:picom)                     echo "picom" ;;
    xbps:sway)                      echo "sway" ;;
    xbps:swaylock)                  echo "swaylock" ;;
    xbps:swayidle)                  echo "swayidle" ;;
    xbps:waybar)                    echo "waybar" ;;
    xbps:bspwm)                     echo "bspwm" ;;
    xbps:sxhkd)                     echo "sxhkd" ;;
    xbps:hyprland)                  echo "hyprland" ;;
    xbps:hyprlock)                  echo "" ;;
    xbps:hypridle)                  echo "" ;;
    xbps:mako)                      echo "mako" ;;
    xbps:wl-clipboard)              echo "wl-clipboard" ;;
    xbps:dmenu)                     echo "dmenu" ;;
    xbps:dunst)                     echo "dunst" ;;
    xbps:kde)                       echo "kde5" ;;
    xbps:build-essential)           echo "base-devel" ;;
    xbps:libx11)                    echo "libX11-devel" ;;
    xbps:libxft)                    echo "libXft-devel" ;;
    xbps:libxinerama)               echo "libXinerama-devel" ;;
    xbps:gtk-engine-murrine)        echo "gtk-engine-murrine" ;;
    xbps:sassc)                     echo "sassc" ;;
    xbps:git)                       echo "git" ;;
    xbps:curl)                      echo "curl" ;;

    *) echo "$1" ;;
  esac
}

ensure_pkg() {
  local logical="$1"
  local real
  real="$(distro_pkg "$logical")"
  if [[ -z "$real" ]]; then
    case "$logical" in
      starship)
        command -v starship >/dev/null 2>&1 && { ok "starship already installed"; return; }
        info "Installing starship via official script…"
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
        ;;
      zoxide)
        command -v zoxide >/dev/null 2>&1 && { ok "zoxide already installed"; return; }
        info "Installing zoxide via official script…"
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        ;;
      fastfetch)
        command -v fastfetch >/dev/null 2>&1 && { ok "fastfetch already installed"; return; }
        info "Installing fastfetch from GitHub release…"
        local arch; arch="$(uname -m)"
        curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${arch}.tar.gz" \
          | sudo tar -xz -C /usr/local/bin fastfetch 2>/dev/null \
          || warn "Could not auto-install fastfetch — install manually from github.com/fastfetch-cli/fastfetch"
        ;;
      *) warn "No package or universal installer for '$logical' on $PM" ;;
    esac
  else
    pkg_installed "$real" && { ok "$real already installed"; return; }
    info "Installing $real…"
    pkg_install "$real" || warn "Failed to install $real"
  fi
}

zsh_plugin_path() {
  local plugin="$1"
  local candidates=(
    "/usr/share/zsh/plugins/${plugin}/${plugin}.zsh"
    "/usr/share/${plugin}/${plugin}.zsh"
    "/usr/share/zsh-${plugin}/${plugin}.zsh"
    "/usr/share/zsh/site-functions/${plugin}.zsh"
    "/usr/share/zsh/vendor-completions/${plugin}.zsh"
  )
  for p in "${candidates[@]}"; do
    [[ -f "$p" ]] && { echo "$p"; return; }
  done
  find /usr/share -name "${plugin}.zsh" 2>/dev/null | head -1
}

detect_pm

# Detect display server
DISPLAY_SERVER="x11"
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  DISPLAY_SERVER="wayland"
  info "Detected Wayland"
elif [[ -n "${DISPLAY:-}" ]]; then
  DISPLAY_SERVER="x11"
  info "Detected X11"
else
  warn "Could not detect display server. Assuming X11."
fi

# ---------- choose WM/DE ----------
clear
cat << 'MENU'
╔════════════════════════════════════════════════╗
║  Tokyo Night Rice Installer — Choose Setup    ║
╚════════════════════════════════════════════════╝

[Tiling WMs]
  1) dwm (minimal, C-based, ultra-light - requires build)
  2) i3 (popular, keyboard-driven, X11)
  3) bspwm (binary space partitioning, powerful)
  4) hyprland (modern Wayland, eye candy ✨)

[Desktop Environments]
  5) KDE Plasma (full-featured, beautiful)

[Other]
  6) Skip WM (use existing)

MENU

read -r -p "Enter choice (1-6): " wm_choice

case "$wm_choice" in
  1) CHOSEN_WM="dwm";      WM_TYPE="x11";     BUILD_REQUIRED=true ;;
  2) CHOSEN_WM="i3";       WM_TYPE="x11";     BUILD_REQUIRED=false ;;
  3) CHOSEN_WM="bspwm";    WM_TYPE="x11";     BUILD_REQUIRED=false ;;
  4) CHOSEN_WM="hyprland"; WM_TYPE="wayland"; BUILD_REQUIRED=false ;;
  5) CHOSEN_WM="kde";      WM_TYPE="";        BUILD_REQUIRED=false ;;
  6) CHOSEN_WM="";         WM_TYPE="";        BUILD_REQUIRED=false ;;
  *) err "Invalid choice"; exit 1 ;;
esac

# ---------- 1. update system ----------
info "Updating package database…"
pm_update

# ---------- 2. base packages ----------
BASE_LOGICAL=(
  starship fastfetch eza bat zoxide fzf zsh zsh-autosuggestions zsh-syntax-highlighting
  nerd-font firasans noto-emoji
  kitty alacritty dunst git curl
)

info "Installing base packages…"
for pkg in "${BASE_LOGICAL[@]}"; do
  ensure_pkg "$pkg"
done

# ---------- 3. theme + icons ----------
install_themes() {
  info "Installing themes…"

  for pkg in gtk-engine-murrine sassc; do
    ensure_pkg "$pkg"
  done

  mkdir -p "$HOME/.themes" "$HOME/.icons"

  if [[ ! -d "$HOME/.themes/TokyoNight" ]]; then
    cd /tmp
    git clone --depth=1 https://github.com/Fausto-Korpsvart/Tokyo-Night-GTK-Theme.git 2>/dev/null || true
    if [[ -d Tokyo-Night-GTK-Theme ]]; then
      cp -r Tokyo-Night-GTK-Theme/Tokyo-Night "$HOME/.themes/" 2>/dev/null || true
      ok "Tokyo Night GTK theme installed"
    fi
    cd - >/dev/null
  else
    ok "Tokyo Night GTK theme already present"
  fi

  if [[ ! -d "$HOME/.icons/Papirus-Dark" ]]; then
    cd /tmp
    git clone --depth=1 https://github.com/PapirusDevelopmentTeam/papirus-icon-theme.git 2>/dev/null || true
    if [[ -d papirus-icon-theme ]]; then
      cp -r papirus-icon-theme/Papirus-Dark "$HOME/.icons/" 2>/dev/null || true
      ok "Papirus Dark icons installed"
    fi
    cd - >/dev/null
  else
    ok "Papirus Dark icons already present"
  fi
}

install_themes

# ---------- 4. install chosen WM/DE ----------

# ===== DWM =====
install_dwm() {
  info "Launching DWM interactive setup wizard…"

  # Try to find install-dwm.sh next to this script, then in PATH
  local dwm_script
  dwm_script="$(dirname "$(realpath "$0")")/install-dwm.sh"
  if [[ ! -f "$dwm_script" ]]; then
    dwm_script="$(command -v install-dwm.sh 2>/dev/null || echo "")"
  fi

  if [[ -n "$dwm_script" && -f "$dwm_script" ]]; then
    bash "$dwm_script"
    return
  fi

  # Fallback: basic build without the wizard
  warn "install-dwm.sh not found — running basic DWM install."
  warn "For the full interactive wizard, run: bash install-dwm.sh"

  for pkg in build-essential libx11 libxft libxinerama; do
    ensure_pkg "$pkg"
  done

  mkdir -p "$HOME/.local/src"
  cd "$HOME/.local/src"

  if [[ ! -d dwm ]]; then
    git clone https://github.com/bakkeby/dwm-flexipatch.git dwm >/dev/null 2>&1
  fi

  cd dwm

  if ! grep -q "tokyonight" config.h 2>/dev/null; then
    cat >> config.h <<'DWMEOF'

/* Tokyo Night colors */
static const char col_bg[]     = "#1a1b26";
static const char col_fg[]     = "#c0caf5";
static const char col_accent[] = "#7aa2f7";
static const char col_green[]  = "#9ece6a";
static const char col_red[]    = "#f7768e";
DWMEOF
  fi

  sudo make clean install >/dev/null 2>&1 && ok "dwm compiled and installed (basic)"
  cd - >/dev/null
}

# ── Shared: Catppuccin Mocha palette ─────────────────────────────────────────
# Used by i3, bspwm, hyprland, kde
CAT_BASE="#1e1e2e";  CAT_MANTLE="#181825"; CAT_CRUST="#11111b"
CAT_SURF0="#313244"; CAT_SURF1="#45475a";  CAT_SURF2="#585b70"
CAT_OVR0="#6c7086";  CAT_OVR1="#7f849c";  CAT_OVR2="#9399b2"
CAT_TEXT="#cdd6f4";  CAT_SUB1="#bac2de";  CAT_SUB0="#a6adc8"
CAT_LAVEN="#b4befe"; CAT_BLUE="#89b4fa";  CAT_SAPH="#74c7ec"
CAT_SKY="#89dceb";   CAT_TEAL="#94e2d5";  CAT_GREEN="#a6e3a1"
CAT_YELL="#f9e2af";  CAT_PEACH="#fab387"; CAT_MAUVE="#cba6f7"
CAT_PINK="#f5c2e7";  CAT_RED="#f38ba8";   CAT_MARO="#eba0ac"
CAT_FLAM="#f2cdcd";  CAT_ROSE="#f5e0dc"

# ── Shared: Catppuccin rofi theme ─────────────────────────────────────────────
write_rofi_catppuccin() {
  mkdir -p "$HOME/.config/rofi"
  cat > "$HOME/.config/rofi/catppuccin.rasi" <<'ROFIEOF'
* {
    bg0:  #1e1e2eff;
    bg1:  #313244ff;
    bg2:  #45475aff;
    fg0:  #cdd6f4ff;
    fg1:  #bac2deff;
    ac0:  #89b4faff;
    ac1:  #cba6f7ff;
    rd:   #f38ba8ff;
    gr:   #a6e3a1ff;
}
configuration {
    modi:            "drun,run,window";
    show-icons:      true;
    icon-theme:      "Papirus-Dark";
    display-drun:    "  Apps";
    display-run:     "  Run";
    display-window:  "  Windows";
    drun-display-format: "{name}";
    font: "JetBrainsMono Nerd Font 11";
}
window {
    transparency:         "real";
    location:             center;
    anchor:               center;
    fullscreen:           false;
    width:                600px;
    border-radius:        12px;
    border:               2px solid;
    border-color:         @ac0;
    background-color:     @bg0;
}
mainbox {
    padding:          12px;
    background-color: transparent;
}
inputbar {
    children:         [ prompt, entry ];
    background-color: @bg1;
    border-radius:    8px;
    padding:          8px 12px;
    margin:           0 0 10px 0;
}
prompt {
    background-color: transparent;
    text-color:       @ac0;
    padding:          0 8px 0 0;
}
entry {
    background-color: transparent;
    text-color:       @fg0;
    placeholder:      "Search...";
    placeholder-color: @fg1;
}
listview {
    columns:          1;
    lines:            8;
    spacing:          4px;
    background-color: transparent;
    scrollbar:        false;
}
element {
    padding:          8px 12px;
    border-radius:    6px;
    background-color: transparent;
    text-color:       @fg1;
    orientation:      horizontal;
}
element selected.normal {
    background-color: @bg1;
    text-color:       @fg0;
    border-left:      3px solid @ac0;
}
element-icon {
    size:             20px;
    padding:          0 8px 0 0;
    background-color: transparent;
}
element-text {
    background-color: transparent;
    text-color:       inherit;
    vertical-align:   0.5;
}
ROFIEOF
  ok "rofi Catppuccin theme written"
}

# ── Shared: Catppuccin dunst config ────────────────────────────────────────────
write_dunst_catppuccin() {
  mkdir -p "$HOME/.config/dunst"
  cat > "$HOME/.config/dunst/dunstrc" <<'DUNSTEOF'
[global]
    monitor                = 0
    follow                 = mouse
    width                  = 340
    height                 = 100
    origin                 = top-right
    offset                 = 12x12
    scale                  = 0
    notification_limit     = 5
    progress_bar           = true
    progress_bar_height    = 8
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 280
    indicate_hidden        = yes
    transparency           = 10
    separator_height       = 1
    padding                = 10
    horizontal_padding     = 14
    text_icon_padding      = 0
    frame_width            = 2
    frame_color            = "#89b4fa"
    separator_color        = frame
    sort                   = yes
    idle_threshold         = 120
    font                   = JetBrainsMono Nerd Font 10
    line_height            = 0
    markup                 = full
    format                 = "<b>%s</b>\n%b"
    alignment              = left
    vertical_alignment     = center
    show_age_threshold     = 60
    ellipsize              = middle
    ignore_newline         = no
    stack_duplicates       = true
    hide_duplicate_count   = false
    show_indicators        = yes
    enable_recursive_icon_lookup = true
    icon_theme             = Papirus-Dark
    icon_position          = left
    min_icon_size          = 32
    max_icon_size          = 64
    sticky_history         = yes
    history_length         = 20
    browser                = /usr/bin/xdg-open
    always_run_script      = true
    title                  = Dunst
    class                  = Dunst
    corner_radius          = 10
    ignore_dbusclose       = false
    force_xwayland         = false
    force_xinerama         = false
    mouse_left_click       = close_current
    mouse_middle_click     = do_action, close_current
    mouse_right_click      = close_all

[urgency_low]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#313244"
    timeout    = 5

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#89b4fa"
    timeout    = 8

[urgency_critical]
    background = "#1e1e2e"
    foreground = "#f38ba8"
    frame_color = "#f38ba8"
    timeout    = 0
DUNSTEOF
  ok "dunst Catppuccin config written"
}

# ── Shared: Catppuccin kitty terminal ──────────────────────────────────────────
write_kitty_catppuccin() {
  mkdir -p "$HOME/.config/kitty"
  cat > "$HOME/.config/kitty/kitty.conf" <<'KITTYEOF'
# Catppuccin Mocha for kitty
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        12.0

background_opacity   0.92
background_blur      24
window_padding_width 12
cursor_shape         block
cursor_blink_interval 0.5
enable_audio_bell    no
scrollback_lines     5000

# Catppuccin Mocha palette
foreground              #cdd6f4
background              #1e1e2e
selection_foreground    #1e1e2e
selection_background    #f5e0dc
cursor                  #f5e0dc
cursor_text_color       #1e1e2e
url_color               #f5e0dc
active_border_color     #b4befe
inactive_border_color   #6c7086
bell_border_color       #f9e2af
active_tab_foreground   #11111b
active_tab_background   #cba6f7
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background      #11111b
mark1_foreground #1e1e2e
mark1_background #b4befe
mark2_foreground #1e1e2e
mark2_background #cba6f7
mark3_foreground #1e1e2e
mark3_background #74c7ec

# 16 terminal colors
color0  #45475a
color1  #f38ba8
color2  #a6e3a1
color3  #f9e2af
color4  #89b4fa
color5  #f5c2e7
color6  #94e2d5
color7  #bac2de
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8
KITTYEOF
  ok "kitty Catppuccin config written"
}

# ── Shared: picom with rounded corners ─────────────────────────────────────────
write_picom_catppuccin() {
  mkdir -p "$HOME/.config/picom"
  cat > "$HOME/.config/picom/picom.conf" <<'PICOMEOF'
# picom — Catppuccin Mocha rice style
backend              = "glx";
vsync                = true;
use-damage           = true;

# Rounded corners
corner-radius        = 10;
rounded-corners-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'"
];

# Shadows
shadow               = true;
shadow-radius        = 20;
shadow-opacity       = 0.45;
shadow-offset-x      = -10;
shadow-offset-y      = -10;
shadow-exclude       = [
    "name = 'Notification'",
    "class_g = 'Conky'",
    "window_type = 'dock'"
];

# Fading
fading               = true;
fade-in-step         = 0.04;
fade-out-step        = 0.04;
fade-delta           = 4;

# Opacity
inactive-opacity     = 0.92;
active-opacity       = 1.0;
frame-opacity        = 1.0;
inactive-opacity-override = false;
focus-exclude        = [ "class_g = 'Cairo-clock'" ];

# Blur (disabled by default — enable for frosted glass)
# blur-method = "dual_kawase";
# blur-strength = 6;
# blur-background = true;
PICOMEOF
  ok "picom Catppuccin config written"
}

# ===== I3 — Catppuccin Mocha (most popular r/unixporn i3 style) ===============
# Inspired by: top i3 rices on r/unixporn (catppuccin + polybar + rofi + picom)
install_i3() {
  info "Installing i3 + polybar + rofi + dunst [Catppuccin Mocha]…"

  for pkg in i3 polybar picom rofi dunst; do
    ensure_pkg "$pkg"
  done
  ok "i3 stack installed"

  write_rofi_catppuccin
  write_dunst_catppuccin
  write_kitty_catppuccin
  write_picom_catppuccin

  mkdir -p "$HOME/.config/i3"
  if [[ ! -f "$HOME/.config/i3/config" ]]; then
    cat > "$HOME/.config/i3/config" <<'I3EOF'
# i3 — Catppuccin Mocha rice
# Inspired by top r/unixporn i3 setups (2024-2025)
set $mod Mod4
font pango:JetBrainsMono Nerd Font 11

# Catppuccin Mocha
set $base   #1e1e2e
set $mantle #181825
set $surf0  #313244
set $surf1  #45475a
set $text   #cdd6f4
set $sub1   #bac2de
set $blue   #89b4fa
set $mauve  #cba6f7
set $green  #a6e3a1
set $red    #f38ba8
set $peach  #fab387
set $laven  #b4befe

# Window borders (accent left border, Catppuccin style)
for_window [class="^.*"] border pixel 2
smart_gaps on
smart_borders on
gaps inner 12
gaps outer 6

client.focused          $blue   $base   $text   $mauve  $blue
client.focused_inactive $surf1  $base   $sub1   $surf0  $surf1
client.unfocused        $surf0  $base   $sub1   $surf0  $surf0
client.urgent           $red    $base   $red    $red    $red

# Core bindings
bindsym $mod+Return       exec kitty
bindsym $mod+d            exec rofi -show drun -theme ~/.config/rofi/catppuccin.rasi
bindsym $mod+Shift+d      exec rofi -show run  -theme ~/.config/rofi/catppuccin.rasi
bindsym $mod+Tab          exec rofi -show window -theme ~/.config/rofi/catppuccin.rasi
bindsym $mod+Shift+q      kill
bindsym $mod+Shift+c      reload
bindsym $mod+Shift+r      restart
bindsym $mod+Shift+e      exec i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'

# Focus
bindsym $mod+h  focus left
bindsym $mod+j  focus down
bindsym $mod+k  focus up
bindsym $mod+l  focus right
bindsym $mod+Left  focus left
bindsym $mod+Down  focus down
bindsym $mod+Up    focus up
bindsym $mod+Right focus right

# Move
bindsym $mod+Shift+h  move left
bindsym $mod+Shift+j  move down
bindsym $mod+Shift+k  move up
bindsym $mod+Shift+l  move right
bindsym $mod+Shift+Left  move left
bindsym $mod+Shift+Down  move down
bindsym $mod+Shift+Up    move up
bindsym $mod+Shift+Right move right

# Layout
bindsym $mod+b  splith
bindsym $mod+v  splitv
bindsym $mod+s  layout stacking
bindsym $mod+w  layout tabbed
bindsym $mod+e  layout toggle split
bindsym $mod+f  fullscreen toggle
bindsym $mod+Shift+space floating toggle
bindsym $mod+space       focus mode_toggle
bindsym $mod+a           focus parent

# Resize
mode "resize" {
    bindsym h resize shrink width  10px
    bindsym j resize grow   height 10px
    bindsym k resize shrink height 10px
    bindsym l resize grow   width  10px
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# Workspaces
set $ws1 "1 "
set $ws2 "2 "
set $ws3 "3 󰨞"
set $ws4 "4 󰊢"
set $ws5 "5 󰭹"
set $ws6 "6 "
set $ws7 "7 "
set $ws8 "8 "
set $ws9 "9 "

bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9

bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9

# Floating rules
for_window [window_role="pop-up"]         floating enable
for_window [window_role="task_dialog"]    floating enable
for_window [class="Pavucontrol"]          floating enable, resize set 680 480
for_window [class="Nitrogen"]             floating enable

# Autostart
exec_always --no-startup-id killall dunst;  dunst &
exec_always --no-startup-id killall polybar; sleep 0.5; polybar main &
exec_always --no-startup-id picom --config ~/.config/picom/picom.conf -b
exec        --no-startup-id xsetroot -solid "#1e1e2e"
I3EOF
    ok "i3 config created (Catppuccin Mocha)"
  fi

  # Polybar — Catppuccin pill-style bar
  mkdir -p "$HOME/.config/polybar"
  if [[ ! -f "$HOME/.config/polybar/config.ini" ]]; then
    cat > "$HOME/.config/polybar/config.ini" <<'POLYEOF'
; polybar — Catppuccin Mocha  (top r/unixporn i3 style)

[colors]
base   = #1e1e2e
mantle = #181825
crust  = #11111b
surf0  = #313244
surf1  = #45475a
text   = #cdd6f4
sub1   = #bac2de
blue   = #89b4fa
mauve  = #cba6f7
green  = #a6e3a1
red    = #f38ba8
peach  = #fab387
yellow = #f9e2af
teal   = #94e2d5
laven  = #b4befe

[bar/main]
width            = 100%
height           = 36
radius           = 0
fixed-center     = true
background       = ${colors.base}
foreground       = ${colors.text}
line-size        = 3
line-color       = ${colors.blue}
border-size      = 0
padding-left     = 1
padding-right    = 1
module-margin    = 1
font-0           = JetBrainsMono Nerd Font:size=11:weight=bold;2
font-1           = JetBrainsMono Nerd Font:size=16;4
font-2           = JetBrainsMono Nerd Font:size=9;2
separator        = |
separator-foreground = ${colors.surf1}
modules-left     = i3 title
modules-center   = date
modules-right    = cpu memory pulseaudio
tray-position    = right
tray-padding     = 6
cursor-click     = pointer
cursor-scroll    = ns-resize

[module/i3]
type                        = internal/i3
format                      = <label-state>
index-sort                  = true
wrapping-scroll             = false
label-mode-padding          = 2
label-mode-foreground       = ${colors.text}
label-mode-background       = ${colors.peach}
label-focused               = %name%
label-focused-background    = ${colors.surf0}
label-focused-foreground    = ${colors.blue}
label-focused-underline     = ${colors.blue}
label-focused-padding       = 3
label-unfocused             = %name%
label-unfocused-padding     = 3
label-unfocused-foreground  = ${colors.sub1}
label-visible               = %name%
label-visible-padding       = 3
label-urgent                = %name%
label-urgent-background     = ${colors.red}
label-urgent-padding        = 3

[module/title]
type             = internal/xwindow
format           = <label>
label            = %title%
label-maxlen     = 50
label-foreground = ${colors.sub1}
label-empty      = Desktop
label-empty-foreground = ${colors.surf1}

[module/date]
type             = internal/date
interval         = 1
date             = %A, %d %B
time             = %H:%M
format           = <label>
label            =  %date%    %time%
label-foreground = ${colors.laven}

[module/cpu]
type             = internal/cpu
interval         = 1
format           = <label>
label            = 󰻠 %percentage%%
label-foreground = ${colors.green}
label-padding    = 1

[module/memory]
type             = internal/memory
interval         = 2
format           = <label>
label            = 󰑭 %percentage%%
label-foreground = ${colors.peach}
label-padding    = 1

[module/pulseaudio]
type             = internal/pulseaudio
format-volume    = <label-volume>
label-volume     = 󰕾 %percentage%%
label-volume-foreground = ${colors.mauve}
label-volume-padding    = 1
label-muted      = 󰖁 muted
label-muted-foreground  = ${colors.surf2}
POLYEOF
    ok "polybar config created (Catppuccin Mocha)"
  fi
}

# ===== BSPWM — Catppuccin Mocha (gh0stzk-inspired, most starred bspwm rice) ==
# Inspired by: gh0stzk/dotfiles — 18-theme bspwm (Andrea/Emilia aesthetic)
install_bspwm() {
  info "Installing bspwm + polybar + rofi + dunst [Catppuccin Mocha]…"

  for pkg in bspwm sxhkd polybar picom rofi dunst; do
    ensure_pkg "$pkg"
  done
  ok "bspwm stack installed"

  write_rofi_catppuccin
  write_dunst_catppuccin
  write_kitty_catppuccin
  write_picom_catppuccin

  mkdir -p "$HOME/.config/bspwm"
  if [[ ! -f "$HOME/.config/bspwm/bspwmrc" ]]; then
    cat > "$HOME/.config/bspwm/bspwmrc" <<'BSPWMEOF'
#!/bin/bash
# bspwmrc — Catppuccin Mocha  (gh0stzk-inspired)

# Desktops
bspc monitor -d '󰲌' '󰲎' '󰲐' '󰲒' '󰲔' '󰲖' '󰲘' '󰲚' '󰲜'

# Window rules
bspc config border_width          2
bspc config window_gap            12
bspc config split_ratio           0.52
bspc config borderless_monocle    true
bspc config gapless_monocle       true
bspc config single_monocle        false
bspc config focus_follows_pointer true

# Catppuccin Mocha border colors
bspc config focused_border_color   "#89b4fa"
bspc config normal_border_color    "#313244"
bspc config presel_feedback_color  "#a6e3a1"
bspc config urgent_border_color    "#f38ba8"

# Floating windows
bspc rule -a Pavucontrol         state=floating  rectangle=700x500+0+0
bspc rule -a 'Yad:*'            state=floating
bspc rule -a Nitrogen            state=floating
bspc rule -a feh                 state=floating

# Autostart
sxhkd &
dunst &
picom --config "$HOME/.config/picom/picom.conf" --daemon &
killall polybar 2>/dev/null; polybar main &
BSPWMEOF
    chmod +x "$HOME/.config/bspwm/bspwmrc"
    ok "bspwmrc created (Catppuccin Mocha)"
  fi

  mkdir -p "$HOME/.config/sxhkd"
  if [[ ! -f "$HOME/.config/sxhkd/sxhkdrc" ]]; then
    cat > "$HOME/.config/sxhkd/sxhkdrc" <<'SXHKDEOF'
# sxhkdrc — gh0stzk-inspired keybindings

# Terminal
super + Return
	kitty
super + shift + Return
	kitty --class floating

# Launcher
super + d
	rofi -show drun -theme ~/.config/rofi/catppuccin.rasi
super + shift + d
	rofi -show run  -theme ~/.config/rofi/catppuccin.rasi
super + Tab
	rofi -show window -theme ~/.config/rofi/catppuccin.rasi

# Window management
super + shift + q
	bspc node -c
super + shift + k
	bspc node -k
super + f
	bspc node -t fullscreen
super + shift + space
	bspc node -t floating
super + ctrl + space
	bspc node -t tiled

# Focus / swap — vim keys
super + {h,j,k,l}
	bspc node -f {west,south,north,east}
super + shift + {h,j,k,l}
	bspc node -s {west,south,north,east}
super + {Left,Down,Up,Right}
	bspc node -f {west,south,north,east}

# Resize
super + alt + {h,j,k,l}
	bspc node -z {left -20 0, bottom 0 20, top 0 -20, right 20 0}
super + ctrl + {h,j,k,l}
	bspc node -z {right -20 0, top 0 20, bottom 0 -20, left 20 0}

# Preselect
super + ctrl + {1-9}
	bspc node -o 0.{1-9}
super + ctrl + space
	bspc node -p cancel

# Desktops
super + {1-9}
	bspc desktop -f '^{1-9}'
super + shift + {1-9}
	bspc node -d '^{1-9}'

# Cycle workspaces
super + bracket{left,right}
	bspc desktop -f {prev,next}.local

# Gaps
super + ctrl + {equal,minus}
	bspc config -d focused window_gap $((`bspc config -d focused window_gap` {+,-} 4))

# Reload sxhkd
super + Escape
	pkill -USR1 -x sxhkd

# Quit bspwm
super + shift + e
	bspc quit
SXHKDEOF
    ok "sxhkdrc created"
  fi

  # Polybar — Catppuccin Mocha (bspwm)
  mkdir -p "$HOME/.config/polybar"
  if [[ ! -f "$HOME/.config/polybar/config.ini" ]]; then
    cat > "$HOME/.config/polybar/config.ini" <<'POLYEOF'
; polybar — Catppuccin Mocha  (bspwm / gh0stzk-inspired)

[colors]
base   = #1e1e2e
surf0  = #313244
surf1  = #45475a
surf2  = #585b70
text   = #cdd6f4
sub1   = #bac2de
blue   = #89b4fa
mauve  = #cba6f7
green  = #a6e3a1
red    = #f38ba8
peach  = #fab387
yellow = #f9e2af
laven  = #b4befe
teal   = #94e2d5

[bar/main]
width            = 100%
height           = 36
background       = ${colors.base}
foreground       = ${colors.text}
fixed-center     = true
border-size      = 0
padding-left     = 1
padding-right    = 1
module-margin    = 1
font-0           = JetBrainsMono Nerd Font:size=11:weight=bold;2
font-1           = JetBrainsMono Nerd Font:size=18;5
separator        = |
separator-foreground = ${colors.surf1}
modules-left     = bspwm title
modules-center   = date
modules-right    = cpu memory pulseaudio
tray-position    = right
tray-padding     = 6
cursor-click     = pointer

[module/bspwm]
type                        = internal/bspwm
format                      = <label-state>
label-focused               = %name%
label-focused-foreground    = ${colors.blue}
label-focused-background    = ${colors.surf0}
label-focused-underline     = ${colors.blue}
label-focused-padding       = 2
label-occupied              = %name%
label-occupied-foreground   = ${colors.sub1}
label-occupied-padding      = 2
label-urgent                = %name%
label-urgent-foreground     = ${colors.red}
label-urgent-background     = ${colors.surf0}
label-urgent-padding        = 2
label-empty                 = %name%
label-empty-foreground      = ${colors.surf2}
label-empty-padding         = 2

[module/title]
type             = internal/xwindow
label            = %title%
label-maxlen     = 45
label-foreground = ${colors.sub1}
label-empty      = Desktop
label-empty-foreground = ${colors.surf1}

[module/date]
type             = internal/date
interval         = 1
date             = %A, %d %B
time             = %H:%M
label            =  %date%    %time%
label-foreground = ${colors.laven}

[module/cpu]
type             = internal/cpu
interval         = 1
label            = 󰻠 %percentage%%
label-foreground = ${colors.green}
label-padding    = 1

[module/memory]
type             = internal/memory
interval         = 2
label            = 󰑭 %percentage%%
label-foreground = ${colors.peach}
label-padding    = 1

[module/pulseaudio]
type             = internal/pulseaudio
label-volume     = 󰕾 %percentage%%
label-volume-foreground = ${colors.mauve}
label-muted      = 󰖁 muted
label-muted-foreground  = ${colors.surf2}
POLYEOF
    ok "polybar config created (Catppuccin Mocha)"
  fi
}

# ===== HYPRLAND — Catppuccin Mocha Frosted Glass ==============
# Inspired by: JaKooLit/Hyprland-Dots (3.4k stars), sameemul-haque/dotfiles
# Most popular Hyprland aesthetic on r/unixporn 2024-2025
install_hyprland() {
  info "Installing hyprland + waybar + swww + swaync [Catppuccin Mocha]…"

  for pkg in hyprland hyprlock hypridle waybar mako wl-clipboard rofi; do
    ensure_pkg "$pkg"
  done

  # swww for wallpaper management (key part of popular Hyprland setups)
  if ! command -v swww >/dev/null 2>&1; then
    case "$PM" in
      pacman) sudo pacman -S --noconfirm --needed swww 2>/dev/null || \
              warn "Install swww from AUR: yay -S swww" ;;
      *) warn "Install swww manually: https://github.com/LGFae/swww" ;;
    esac
  fi

  write_kitty_catppuccin
  write_rofi_catppuccin

  ok "Hyprland stack installed"

  mkdir -p "$HOME/.config/hypr"
  if [[ ! -f "$HOME/.config/hypr/hyprland.conf" ]]; then
    cat > "$HOME/.config/hypr/hyprland.conf" <<'HYPREOF'
# hyprland.conf — Catppuccin Mocha Frosted Glass
# Inspired by: JaKooLit/Hyprland-Dots, sameemul-haque/dotfiles (r/unixporn)

monitor=,highres,auto,1

# Environment
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,catppuccin-mocha-dark-cursors
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_QPA_PLATFORM,wayland
env = GDK_BACKEND,wayland,x11
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

# Autostart
exec-once = waybar
exec-once = dunst
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = swww-daemon
exec-once = hypridle
exec-once = wl-paste --type text  --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store

# General
general {
    gaps_in              = 6
    gaps_out             = 15
    border_size          = 2
    col.active_border    = rgba(89b4faff) rgba(cba6f7ff) 45deg
    col.inactive_border  = rgba(313244ff)
    layout               = dwindle
    allow_tearing        = false
    resize_on_border     = true
}

# Decoration — frosted glass (the iconic Hyprland look)
decoration {
    rounding             = 12

    active_opacity       = 1.0
    inactive_opacity     = 0.92
    fullscreen_opacity   = 1.0

    blur {
        enabled          = true
        size             = 8
        passes           = 3
        noise            = 0.0117
        contrast         = 0.8916
        brightness       = 0.8172
        vibrancy         = 0.1696
        vibrancy_darkness = 0.0
        new_optimizations = true
        xray             = false
        special          = true
    }

    drop_shadow          = true
    shadow_range         = 30
    shadow_render_power  = 3
    shadow_color         = rgba(1a1a1aee)
    shadow_ignore_window = true
}

# Animations — smooth Catppuccin-style
animations {
    enabled = yes

    bezier = overshot,    0.05, 0.9, 0.1, 1.05
    bezier = smoothOut,   0.5,  0,   0.99, 0.99
    bezier = smoothIn,    0.5, -0.5, 0.68, 1.5
    bezier = linear,      0.0,  0.0, 1.0,  1.0

    animation = windows,     1, 5, overshot,  slide
    animation = windowsIn,   1, 5, overshot,  slide
    animation = windowsOut,  1, 4, smoothOut, slide
    animation = windowsMove, 1, 4, smoothIn,  slide
    animation = border,      1, 10, linear
    animation = borderangle, 1, 100, linear, loop
    animation = fade,        1, 5, smoothIn
    animation = fadeOut,     1, 5, smoothOut
    animation = workspaces,  1, 6, overshot, slidevert
}

# Layouts
dwindle {
    pseudotile         = yes
    preserve_split     = yes
    smart_split        = false
    smart_resizing     = true
}

master {
    new_is_master      = true
}

# Input
input {
    kb_layout         = us
    follow_mouse      = 1
    sensitivity       = 0
    touchpad {
        natural_scroll = yes
        tap-to-click   = yes
    }
}

gestures {
    workspace_swipe         = true
    workspace_swipe_fingers = 3
}

# Misc
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo   = true
    disable_splash_rendering = true
    mouse_move_enables_dpms = true
    key_press_enables_dpms  = true
}

# Window rules
windowrulev2 = suppressevent maximize, class:.*
windowrulev2 = float,  class:^(Pavucontrol)$
windowrulev2 = float,  class:^(blueman-manager)$
windowrulev2 = float,  class:^(nm-connection-editor)$
windowrulev2 = float,  title:^(Picture-in-Picture)$
windowrulev2 = float,  class:^(org.kde.polkit-kde-authentication-agent-1)$
windowrulev2 = opacity 0.88 0.88, class:^(kitty)$
windowrulev2 = opacity 0.90 0.85, class:^(Code)$
windowrulev2 = opacity 0.85 0.80, class:^(org.pwmt.zathura)$

# Layer rules (blur on waybar, rofi, dunst)
layerrule = blur, waybar
layerrule = blur, rofi
layerrule = ignorezero, rofi

# Keybindings
$mainMod = SUPER

# Core
bind = $mainMod,       Return,     exec, kitty
bind = $mainMod,       Q,          killactive
bind = $mainMod SHIFT, E,          exit
bind = $mainMod,       F,          fullscreen, 0
bind = $mainMod SHIFT, F,          fullscreen, 1
bind = $mainMod,       Space,      togglefloating
bind = $mainMod,       P,          pseudo
bind = $mainMod,       J,          togglesplit

# Launcher (rofi with Catppuccin theme)
bind = $mainMod, D,          exec, rofi -show drun   -theme ~/.config/rofi/catppuccin.rasi
bind = $mainMod, R,          exec, rofi -show run    -theme ~/.config/rofi/catppuccin.rasi
bind = $mainMod, Tab,        exec, rofi -show window -theme ~/.config/rofi/catppuccin.rasi

# Wallpaper
bind = $mainMod, W, exec, swww img "$(find ~/Pictures/wallpapers -type f | shuf -n1)" \
    --transition-type random --transition-duration 1

# Screenshots
bind = ,      Print, exec, hyprshot -m output
bind = SHIFT, Print, exec, hyprshot -m region

# Focus
bind = $mainMod, H,     movefocus, l
bind = $mainMod, J,     movefocus, d
bind = $mainMod, K,     movefocus, u
bind = $mainMod, L,     movefocus, r
bind = $mainMod, left,  movefocus, l
bind = $mainMod, down,  movefocus, d
bind = $mainMod, up,    movefocus, u
bind = $mainMod, right, movefocus, r

# Move windows
bind = $mainMod SHIFT, H,     movewindow, l
bind = $mainMod SHIFT, J,     movewindow, d
bind = $mainMod SHIFT, K,     movewindow, u
bind = $mainMod SHIFT, L,     movewindow, r

# Resize
binde = $mainMod CTRL, H, resizeactive, -30 0
binde = $mainMod CTRL, J, resizeactive, 0  30
binde = $mainMod CTRL, K, resizeactive, 0 -30
binde = $mainMod CTRL, L, resizeactive,  30 0

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9

# Scroll workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up,   workspace, e-1

# Move/resize with mouse
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Volume / brightness
bindl = , XF86AudioRaiseVolume,  exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@   5%+
bindl = , XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@          5%-
bindl = , XF86AudioMute,         exec, wpctl set-mute   @DEFAULT_AUDIO_SINK@          toggle
bindl = , XF86MonBrightnessUp,   exec, brightnessctl set 10%+
bindl = , XF86MonBrightnessDown, exec, brightnessctl set 10%-
HYPREOF
    ok "hyprland.conf created (Catppuccin Mocha Frosted Glass)"
  fi

  # Waybar — floating frosted glass bottom bar
  mkdir -p "$HOME/.config/waybar"
  if [[ ! -f "$HOME/.config/waybar/config" ]]; then
    cat > "$HOME/.config/waybar/config" <<'WAYBAREOF'
{
  "layer":     "top",
  "position":  "top",
  "height":    38,
  "spacing":   4,
  "margin-top":    8,
  "margin-left":   12,
  "margin-right":  12,

  "modules-left":   ["hyprland/workspaces", "hyprland/window"],
  "modules-center": ["clock"],
  "modules-right":  ["pulseaudio", "network", "cpu", "memory", "battery", "tray"],

  "hyprland/workspaces": {
    "format":        "{icon}",
    "on-scroll-up":  "hyprctl dispatch workspace e+1",
    "on-scroll-down":"hyprctl dispatch workspace e-1",
    "format-icons": {
      "1": "󰲌", "2": "󰲎", "3": "󰲐", "4": "󰲒", "5": "󰲔",
      "6": "󰲖", "7": "󰲘", "8": "󰲚", "9": "󰲜",
      "urgent":  "󱍒",
      "focused": "󰮯",
      "default": "○"
    },
    "persistent-workspaces": { "*": 9 }
  },
  "hyprland/window": {
    "max-length":  40,
    "separate-outputs": true
  },
  "clock": {
    "format":      "  {:%H:%M}",
    "format-alt":  "  {:%A, %d %B %Y}",
    "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
  },
  "cpu": {
    "interval": 2,
    "format":   "󰻠 {usage}%",
    "tooltip":  true
  },
  "memory": {
    "interval": 5,
    "format":   "󰑭 {percentage}%",
    "tooltip-format": "{used:0.1f}G / {total:0.1f}G"
  },
  "battery": {
    "states":       { "good": 95, "warning": 30, "critical": 15 },
    "format":       "{icon} {capacity}%",
    "format-full":  "󰁹 {capacity}%",
    "format-icons": ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
  },
  "network": {
    "format-wifi":       "󰤨 {essid}",
    "format-ethernet":   "󰈀 {ifname}",
    "format-disconnected":"󰤭 offline",
    "tooltip-format":    "{ipaddr}"
  },
  "pulseaudio": {
    "format":          "{icon} {volume}%",
    "format-muted":    "󰖁 muted",
    "format-icons":    { "default": ["󰕿","󰖀","󰕾"] },
    "on-click":        "pavucontrol"
  },
  "tray": {
    "icon-size":   18,
    "spacing":     8
  }
}
WAYBAREOF

    cat > "$HOME/.config/waybar/style.css" <<'WAYBARCSSEOF'
/* waybar — Catppuccin Mocha Frosted Glass (r/unixporn top Hyprland style) */
* {
  border:        none;
  border-radius: 0;
  font-family:   "JetBrainsMono Nerd Font";
  font-size:     12px;
  min-height:    0;
}

window#waybar {
  background:    rgba(30, 30, 46, 0.82);
  color:         #cdd6f4;
  border-radius: 14px;
  border:        1px solid rgba(137, 180, 250, 0.25);
}

tooltip {
  background:    rgba(30, 30, 46, 0.95);
  border:        1px solid rgba(137, 180, 250, 0.4);
  border-radius: 8px;
  color:         #cdd6f4;
}

/* Workspaces */
#workspaces {
  padding: 0 6px;
}
#workspaces button {
  padding:       4px 8px;
  margin:        2px 2px;
  border-radius: 8px;
  color:         #6c7086;
  background:    transparent;
  transition:    all 0.2s ease;
}
#workspaces button.focused,
#workspaces button.active {
  color:      #89b4fa;
  background: rgba(137, 180, 250, 0.18);
}
#workspaces button.urgent {
  color:      #f38ba8;
  background: rgba(243, 139, 168, 0.18);
}
#workspaces button:hover {
  color:      #cdd6f4;
  background: rgba(205, 214, 244, 0.1);
}

/* Window title */
#window {
  color:        #a6adc8;
  font-style:   italic;
  padding:      0 8px;
}

/* Clock */
#clock {
  color:         #b4befe;
  font-weight:   bold;
  padding:       0 12px;
}

/* Modules right */
#cpu        { color: #a6e3a1; padding: 0 8px; }
#memory     { color: #fab387; padding: 0 8px; }
#battery    { color: #f9e2af; padding: 0 8px; }
#network    { color: #89dceb; padding: 0 8px; }
#pulseaudio { color: #cba6f7; padding: 0 8px; }
#tray       { padding: 0 6px; }

#battery.warning  { color: #f9e2af; }
#battery.critical { color: #f38ba8; animation-name: blink; animation-duration: 0.5s; animation-iteration-count: infinite; }
WAYBARCSSEOF

    # hyprlock — Catppuccin lock screen
    cat > "$HOME/.config/hypr/hyprlock.conf" <<'HYPRLOCKCEOF'
# hyprlock — Catppuccin Mocha
background {
    monitor     =
    blur_passes = 3
    blur_size   = 8
    noise       = 0.0117
    contrast    = 1.0
    brightness  = 0.5
}
input-field {
    monitor       =
    size          = 300, 50
    outline_thickness = 2
    dots_size     = 0.33
    dots_spacing  = 0.15
    outer_color   = rgba(89b4faff)
    inner_color   = rgba(30,30,46,0.9)
    font_color    = rgb(cdd6f4)
    fade_on_empty = true
    placeholder_text = <i>Password...</i>
    hide_input    = false
    position      = 0, -120
    halign        = center
    valign        = center
}
label {
    monitor   =
    text      = cmd[update:1000] echo "$(date +'%H:%M')"
    color     = rgba(203, 166, 247, 0.9)
    font_size = 90
    font_family = JetBrainsMono Nerd Font
    position  = 0, 80
    halign    = center
    valign    = center
}
label {
    monitor   =
    text      = cmd[update:1000] echo "$(date +'%A, %d %B %Y')"
    color     = rgba(205, 214, 244, 0.7)
    font_size = 18
    font_family = JetBrainsMono Nerd Font
    position  = 0, -20
    halign    = center
    valign    = center
}
HYPRLOCKCEOF

    ok "waybar + hyprlock created (Catppuccin Mocha Frosted Glass)"
  fi
}

# ===== KDE PLASMA — Catppuccin KDE (most starred KDE rice on GitHub) ==========
# Inspired by: catppuccin/kde + Kvantum theming
install_kde() {
  info "Installing KDE Plasma + Catppuccin theme + Kvantum…"
  ensure_pkg "kde"

  # Install Kvantum (app theming engine, essential for Catppuccin KDE)
  case "$PM" in
    pacman) sudo pacman -S --noconfirm --needed kvantum qt5ct qt6ct kvantum-qt5 2>/dev/null || true ;;
    apt)    sudo apt-get install -y qt5-style-kvantum qt5-style-kvantum-themes 2>/dev/null || true ;;
    dnf)    sudo dnf install -y kvantum 2>/dev/null || true ;;
    *) warn "Install Kvantum manually for app theming" ;;
  esac

  ok "KDE + Kvantum installed"

  # Clone and install Catppuccin KDE (official theme)
  if [[ ! -d "$HOME/.themes/Catppuccin-Mocha-Blue" ]]; then
    info "Installing Catppuccin KDE theme…"
    cd /tmp
    git clone --depth=1 https://github.com/catppuccin/kde catppuccin-kde 2>/dev/null || true
    if [[ -d catppuccin-kde ]]; then
      mkdir -p "$HOME/.themes" "$HOME/.local/share/plasma/desktoptheme" \
               "$HOME/.local/share/color-schemes" "$HOME/.local/share/aurorae/themes"
      # Run their installer if it exists, otherwise copy manually
      if [[ -f catppuccin-kde/install.sh ]]; then
        bash catppuccin-kde/install.sh --flavor mocha --accent blue 2>/dev/null || true
      fi
      ok "Catppuccin KDE theme installed"
    fi
    cd - >/dev/null
  fi

  # Clone Kvantum Catppuccin theme
  if [[ ! -d "$HOME/.config/Kvantum/catppuccin-mocha-blue" ]]; then
    info "Installing Catppuccin Kvantum theme…"
    cd /tmp
    git clone --depth=1 https://github.com/catppuccin/Kvantum catppuccin-kvantum 2>/dev/null || true
    if [[ -d catppuccin-kvantum ]]; then
      mkdir -p "$HOME/.config/Kvantum"
      cp -r catppuccin-kvantum/themes/catppuccin-mocha-blue "$HOME/.config/Kvantum/" 2>/dev/null || true
      ok "Kvantum Catppuccin theme copied"
    fi
    cd - >/dev/null
  fi

  # Apply via kwriteconfig (KDE config tool)
  if command -v kwriteconfig6 >/dev/null 2>&1 || command -v kwriteconfig5 >/dev/null 2>&1; then
    _kw() { command -v kwriteconfig6 >/dev/null 2>&1 && kwriteconfig6 "$@" || kwriteconfig5 "$@"; }

    # Color scheme
    _kw --file kdeglobals --group General --key ColorScheme "CatppuccinMochaBlue"

    # Window decoration
    _kw --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__CatppuccinMochaBlue"
    _kw --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae"

    # Blur effects
    _kw --file kwinrc --group Plugins --key blurEnabled "true"
    _kw --file kwinrc --group Effect-blur --key BlurStrength "6"

    # Rounded corners (KWin)
    _kw --file kwinrc --group Plugins --key roundedcornersEnabled "true"

    # Icon theme
    _kw --file kdeglobals --group Icons --key Theme "Papirus-Dark"

    # Kvantum engine for Qt apps
    _kw --file kdeglobals --group KDE --key widgetStyle "kvantum-dark"

    # Konsole catppuccin profile
    mkdir -p "$HOME/.local/share/konsole"
    cat > "$HOME/.local/share/konsole/Catppuccin.profile" <<'KONSOLEEOF'
[Appearance]
ColorScheme=Catppuccin-Mocha
Font=JetBrainsMono Nerd Font,12,-1,5,50,0,0,0,0,0

[General]
Name=Catppuccin
Parent=FALLBACK/
TerminalColumns=120
TerminalRows=30
KONSOLEEOF

    # Konsole Catppuccin color scheme
    mkdir -p "$HOME/.local/share/konsole"
    cat > "$HOME/.local/share/konsole/Catppuccin-Mocha.colorscheme" <<'COLORSEOF'
[Background]
Color=30,30,46

[BackgroundIntense]
Color=24,24,37

[Foreground]
Color=205,214,244

[ForegroundIntense]
Color=205,214,244

[Color0]
Color=69,71,90

[Color1]
Color=243,139,168

[Color2]
Color=166,227,161

[Color3]
Color=249,226,175

[Color4]
Color=137,180,250

[Color5]
Color=203,166,247

[Color6]
Color=148,226,213

[Color7]
Color=186,194,222

[Color0Intense]
Color=88,91,112

[Color1Intense]
Color=243,139,168

[Color2Intense]
Color=166,227,161

[Color3Intense]
Color=249,226,175

[Color4Intense]
Color=137,180,250

[Color5Intense]
Color=203,166,247

[Color6Intense]
Color=148,226,213

[Color7Intense]
Color=166,173,200

[General]
Anchor=0.5,0.5
Blur=true
ColorRandomization=false
Description=Catppuccin Mocha
FillStyle=Tile
Opacity=0.92
Wallpaper=
COLORSEOF

    ok "KDE Catppuccin theme applied"
    warn "Log out and back in (or run: qdbus org.kde.KWin /KWin reconfigure) to apply"
  else
    warn "kwriteconfig not found — apply Catppuccin theme manually in System Settings"
    warn "Theme name: Catppuccin Mocha Blue  |  Icons: Papirus-Dark  |  Engine: Kvantum"
  fi
}

case "$CHOSEN_WM" in
  dwm)      install_dwm ;;
  i3)       install_i3 ;;
  bspwm)    install_bspwm ;;
  hyprland) install_hyprland ;;
  kde)      install_kde ;;
  *)        warn "No WM selected" ;;
esac

# ---------- 5. GTK settings ----------
info "Configuring GTK theme…"
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" <<'GTKEOF'
[Settings]
gtk-theme-name=Tokyo-Night
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 10
gtk-application-prefer-dark-theme=true
gtk-cursor-theme-size=24
GTKEOF
ok "GTK configured"

# ---------- 6. shell setup ----------
info "Configuring shell…"
cat > "$HOME/.config/starship.toml" <<'STARSHIPEOF'
"$schema" = 'https://starship.rs/config-schema.json'
palette = 'tokyonight'
format = """
[](color_bg0)\
$os\
$username\
[](bg:color_bg1 fg:color_bg0)\
$directory\
[](fg:color_bg1 bg:color_bg2)\
$git_branch\
$git_status\
[](fg:color_bg2 bg:color_bg3)\
$nodejs$rust$golang$python\
[](fg:color_bg3)\
$fill\
$cmd_duration\
$line_break$character"""

[palettes.tokyonight]
color_fg0 = '#c0caf5'
color_bg0 = '#1a1b26'
color_bg1 = '#24283b'
color_bg2 = '#414868'
color_bg3 = '#565f89'

[os]
disabled = false
style = "bg:color_bg0 fg:color_fg0"
[os.symbols]
Linux    = "󰌽 "
Arch     = "󰣇 "
Ubuntu   = " "
Debian   = " "
Fedora   = " "
openSUSE = " "

[character]
success_symbol = '[](bold fg:#9ece6a)'
error_symbol   = '[](bold fg:#f7768e)'
STARSHIPEOF

ZSHRC="$HOME/.zshrc"
[[ -f "$ZSHRC" ]] || touch "$ZSHRC"

if [[ ! -f "$HOME/.zshrc.backup" ]]; then
  cp "$ZSHRC" "$HOME/.zshrc.backup"
fi

if ! grep -qF "# >>> rice setup" "$ZSHRC"; then
  info "Resolving zsh plugin paths…"
  AUTOSUGGEST_PATH="$(zsh_plugin_path zsh-autosuggestions)"
  HIGHLIGHT_PATH="$(zsh_plugin_path zsh-syntax-highlighting)"
  [[ -z "$AUTOSUGGEST_PATH" ]] && warn "zsh-autosuggestions path not found"
  [[ -z "$HIGHLIGHT_PATH"   ]] && warn "zsh-syntax-highlighting path not found"

  cat >> "$ZSHRC" <<EOF

# >>> rice setup (managed) >>>
eval "\$(starship init zsh)"
eval "\$(zoxide init zsh)"
source <(fzf --zsh)

alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first --git'
alias la='eza -lah --icons --group-directories-first --git'
alias cat='bat --paging=never'

${AUTOSUGGEST_PATH:+source "$AUTOSUGGEST_PATH"}
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'
${HIGHLIGHT_PATH:+source "$HIGHLIGHT_PATH"}

if [[ -o interactive ]]; then fastfetch; fi
# <<< rice setup <<<
EOF
  ok "~/.zshrc updated"
fi

# ---------- final message ----------
clear
cat << 'ENDMSG'
╔════════════════════════════════════════════════╗
║  ✅  Rice installed successfully!              ║
╚════════════════════════════════════════════════╝

ENDMSG

echo "Selected: ${CHOSEN_WM:-none}"
echo ""
echo "Next steps:"
echo "  1. Reload shell:          exec zsh"
[[ -n "${CHOSEN_WM:-}" ]] && echo "  2. Verify configs:        ls ~/.config/$CHOSEN_WM/"
echo "  3. Start your session:    (select at login screen or startx)"
echo ""
echo "Customization locations:"
case "${CHOSEN_WM:-}" in
  dwm)
    echo "  Source:      ~/builds/dwm/"
    echo "  Edit config: ~/builds/dwm/config.h"
    echo "  Recompile:   cd ~/builds/dwm && sudo make install"
    ;;
  i3)
    echo "  Config:      ~/.config/i3/config"
    echo "  Bar:         ~/.config/polybar/config.ini"
    echo "  Compositor:  ~/.config/picom/picom.conf"
    ;;
  bspwm)
    echo "  Config:      ~/.config/bspwm/bspwmrc"
    echo "  Keys:        ~/.config/sxhkd/sxhkdrc"
    echo "  Bar:         ~/.config/polybar/config.ini"
    ;;
  hyprland)
    echo "  Config:      ~/.config/hypr/hyprland.conf"
    echo "  Bar:         ~/.config/waybar/config"
    echo "  Styling:     ~/.config/waybar/style.css"
    ;;
  kde)
    echo "  Settings:    System Settings > Appearance"
    echo "  Theme:       Switch to 'Tokyo-Night'"
    echo "  Icons:       Switch to 'Papirus-Dark'"
    ;;
esac

echo ""
echo "Keybindings:"
echo "  Super+Return     Open terminal"
echo "  Super+D          Application menu"
echo "  Super+1-5        Switch workspace"
echo "  Arrow keys       Navigate windows"
echo ""
echo "Perfect for r/unixporn!"
