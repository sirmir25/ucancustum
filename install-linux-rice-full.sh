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
  info "Installing dwm (building from source)…"

  for pkg in build-essential libx11 libxft libxinerama; do
    ensure_pkg "$pkg"
  done

  mkdir -p "$HOME/builds"
  cd "$HOME/builds"

  if [[ ! -d dwm ]]; then
    git clone https://git.suckless.org/dwm >/dev/null 2>&1
  fi

  cd dwm

  if ! grep -q "tokyonight" config.h 2>/dev/null; then
    cat >> config.h <<'DWMEOF'

/* Tokyo Night colors */
static const char col_bg[]    = "#1a1b26";
static const char col_fg[]    = "#c0caf5";
static const char col_blue[]  = "#7aa2f7";
static const char col_green[] = "#9ece6a";
static const char col_red[]   = "#f7768e";
DWMEOF
  fi

  sudo make install >/dev/null 2>&1 && ok "dwm compiled and installed"
  cd - >/dev/null
}

# ===== I3 =====
install_i3() {
  info "Installing i3 + polybar…"

  for pkg in i3 i3status dmenu polybar picom; do
    ensure_pkg "$pkg"
  done
  ok "i3 + polybar installed"

  mkdir -p "$HOME/.config/i3"
  if [[ ! -f "$HOME/.config/i3/config" ]]; then
    cat > "$HOME/.config/i3/config" <<'I3EOF'
set $mod Mod4
font pango:JetBrainsMono Nerd Font 10

set $bg     #1a1b26
set $fg     #c0caf5
set $blue   #7aa2f7
set $green  #9ece6a
set $red    #f7768e

client.focused          $blue   $bg $fg $green
client.unfocused        $bg     $bg $fg $bg
client.focused_inactive $bg     $bg $fg $bg
client.urgent           $red    $red $fg $red

gaps inner 8
gaps outer 4
smart_gaps on
for_window [class="^.*"] border pixel 2

bindsym $mod+Return exec kitty
bindsym $mod+d exec dmenu_run -nb "$bg" -nf "$fg" -sb "$blue"
bindsym $mod+Shift+q kill
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"

bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5

bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5

bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart

exec_always --no-startup-id killall polybar; polybar main
exec_always --no-startup-id picom -b
I3EOF
    ok "i3 config created"
  fi

  mkdir -p "$HOME/.config/polybar"
  if [[ ! -f "$HOME/.config/polybar/config.ini" ]]; then
    cat > "$HOME/.config/polybar/config.ini" <<'POLYEOF'
[bar/main]
width = 100%
height = 28
background = #1a1b26
foreground = #c0caf5
line-color = #7aa2f7
font-0 = JetBrainsMono Nerd Font:pixelsize=10
modules-left = i3
modules-right = cpu memory date
module-margin = 1
padding = 1

[module/i3]
type = internal/i3
format = <label-state>
label-focused-background = #7aa2f7
label-focused-foreground = #1a1b26
label-focused-padding = 2

[module/cpu]
type = internal/cpu
format = <label>
label = 󰻠 %percentage%%
label-foreground = #9ece6a

[module/memory]
type = internal/memory
format = <label>
label = 󰑭 %percentage%%
label-foreground = #e0af68

[module/date]
type = internal/date
format = <label>
date = %H:%M:%S
label = 󰃭 %date%
label-foreground = #7aa2f7
POLYEOF
    ok "polybar config created"
  fi

  mkdir -p "$HOME/.config/picom"
  if [[ ! -f "$HOME/.config/picom/picom.conf" ]]; then
    cat > "$HOME/.config/picom/picom.conf" <<'PICOMEOF'
backend = "glx"
vsync = true
blur-method = "dual_kawase"
blur-strength = 10
shadow = true
shadow-radius = 8
shadow-opacity = 0.3
fading = true
fade-in-step = 0.03
fade-out-step = 0.03
PICOMEOF
    ok "picom config created"
  fi
}

# ===== BSPWM =====
install_bspwm() {
  info "Installing bspwm + polybar…"

  for pkg in bspwm sxhkd polybar dmenu picom; do
    ensure_pkg "$pkg"
  done
  ok "bspwm + polybar installed"

  mkdir -p "$HOME/.config/bspwm"
  if [[ ! -f "$HOME/.config/bspwm/bspwmrc" ]]; then
    cat > "$HOME/.config/bspwm/bspwmrc" <<'BSPWMEOF'
#!/bin/bash
bspc monitor -d 1 2 3 4 5

bspc config border_width 2
bspc config window_gap 8
bspc config focused_border_color "#7aa2f7"
bspc config normal_border_color "#1a1b26"
bspc config presel_border_color "#414868"

bspc config split_ratio 0.52
bspc config borderless_monocle true
bspc config gapless_monocle true

sxhkd &
polybar main &
picom -b &
BSPWMEOF
    chmod +x "$HOME/.config/bspwm/bspwmrc"
    ok "bspwm config created"
  fi

  mkdir -p "$HOME/.config/sxhkd"
  if [[ ! -f "$HOME/.config/sxhkd/sxhkdrc" ]]; then
    cat > "$HOME/.config/sxhkd/sxhkdrc" <<'SXHKDEOF'
super + Return
	kitty

super + d
	dmenu_run

super + Shift + q
	bspc node -c

super + Left
	bspc node -f west

super + Down
	bspc node -f south

super + Up
	bspc node -f north

super + Right
	bspc node -f east

super + {1-5}
	bspc desktop -f '^{1-5}'

super + shift + {1-5}
	bspc node -d '^{1-5}'
SXHKDEOF
    ok "sxhkd keybindings created"
  fi

  mkdir -p "$HOME/.config/polybar"
  if [[ ! -f "$HOME/.config/polybar/config.ini" ]]; then
    cat > "$HOME/.config/polybar/config.ini" <<'POLYEOF'
[bar/main]
width = 100%
height = 28
background = #1a1b26
foreground = #c0caf5
line-color = #7aa2f7
font-0 = JetBrainsMono Nerd Font:pixelsize=10
modules-left = bspwm
modules-right = cpu memory date
module-margin = 1
padding = 1

[module/bspwm]
type = internal/bspwm
format = <label-state>
label-focused-background = #7aa2f7
label-focused-foreground = #1a1b26
label-focused-padding = 2

[module/cpu]
type = internal/cpu
format = <label>
label = 󰻠 %percentage%%
label-foreground = #9ece6a

[module/memory]
type = internal/memory
format = <label>
label = 󰑭 %percentage%%
label-foreground = #e0af68

[module/date]
type = internal/date
format = <label>
date = %H:%M:%S
label = 󰃭 %date%
label-foreground = #7aa2f7
POLYEOF
    ok "polybar config created"
  fi
}

# ===== HYPRLAND =====
install_hyprland() {
  info "Installing hyprland + waybar…"

  for pkg in hyprland hyprlock hypridle waybar mako dmenu wl-clipboard; do
    ensure_pkg "$pkg"
  done
  ok "hyprland + waybar installed"

  mkdir -p "$HOME/.config/hypr"
  if [[ ! -f "$HOME/.config/hypr/hyprland.conf" ]]; then
    cat > "$HOME/.config/hypr/hyprland.conf" <<'HYPREOF'
monitor=,highres,auto,1

env = XCURSOR_SIZE,24

general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(7aa2f7ff)
    col.inactive_border = rgba(1a1b26ff)
    layout = dwindle
    allow_tearing = false
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = yes
    preserve_split = yes
}

input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0
}

$mainMod = SUPER

bind = $mainMod, Q, exec, kitty
bind = $mainMod, M, exit
bind = $mainMod, E, exec, dmenu_run
bind = $mainMod, Space, togglefloating

bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5

windowrulev2 = suppressevent maximize, class:.*

exec-once = waybar
exec-once = mako
HYPREOF
    ok "hyprland config created"
  fi

  mkdir -p "$HOME/.config/waybar"
  if [[ ! -f "$HOME/.config/waybar/config" ]]; then
    cat > "$HOME/.config/waybar/config" <<'WAYBAREOF'
{
  "position": "top",
  "height": 28,
  "modules-left": ["hyprland/workspaces"],
  "modules-center": ["hyprland/window"],
  "modules-right": ["cpu", "memory", "pulseaudio", "clock"],

  "hyprland/workspaces": {
    "format": "{icon}",
    "format-icons": {
      "1": "󰣇",
      "2": "󰈹",
      "3": "󰨞",
      "4": "󰊢",
      "5": "󱇪"
    }
  },
  "cpu":        { "format": "󰻠 {usage}%" },
  "memory":     { "format": "󰑭 {percentage}%" },
  "pulseaudio": { "format": "󰕾 {volume}%" },
  "clock":      { "format": "󰃭 {:%H:%M:%S}" }
}
WAYBAREOF

    cat > "$HOME/.config/waybar/style.css" <<'WAYBARCSSEOF'
* {
  all: unset;
  font-family: "JetBrainsMono Nerd Font";
  font-size: 12px;
}

window {
  background-color: #1a1b26;
  color: #c0caf5;
  border-bottom: 2px solid #7aa2f7;
}

#workspaces button {
  padding: 0 8px;
  margin: 0 2px;
}

#workspaces button.active {
  background-color: #7aa2f7;
  color: #1a1b26;
  border-radius: 4px;
}

#cpu        { color: #9ece6a; padding: 0 10px; }
#memory     { color: #e0af68; padding: 0 10px; }
#pulseaudio { color: #7aa2f7; padding: 0 10px; }
#clock      { color: #7aa2f7; padding: 0 10px; }
WAYBARCSSEOF

    ok "waybar config created"
  fi
}

# ===== KDE PLASMA =====
install_kde() {
  info "Installing KDE Plasma…"
  ensure_pkg "kde"
  ok "KDE Plasma installed"
  warn "KDE Plasma installed. Configure via System Settings > Appearance"
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
