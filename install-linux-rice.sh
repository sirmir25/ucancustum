#!/usr/bin/env bash
# install-linux-rice.sh — Full Tokyo Night rice for Linux (r/unixporn style)
#
# Complete desktop rice: WM + bar + compositor + theme + fonts + wallpaper
#
# Supports:
#   - i3 / sway (tiling window managers)
#   - polybar / waybar (status bars)
#   - picom (compositor for X11)
#   - GTK Tokyo Night theme
#   - Full shell setup (zsh, starship, etc)
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
    pacman:zsh)                     echo "zsh" ;;
    pacman:zsh-autosuggestions)     echo "zsh-autosuggestions" ;;
    pacman:zsh-syntax-highlighting) echo "zsh-syntax-highlighting" ;;
    pacman:nerd-font)               echo "ttf-jetbrains-mono-nerd" ;;
    pacman:eza)                     echo "eza" ;;
    pacman:bat)                     echo "bat" ;;
    pacman:fzf)                     echo "fzf" ;;
    pacman:zoxide)                  echo "zoxide" ;;
    pacman:fastfetch)               echo "fastfetch" ;;
    pacman:starship)                echo "starship" ;;
    pacman:kitty)                   echo "kitty" ;;
    pacman:alacritty)               echo "alacritty" ;;
    pacman:i3)                      echo "i3-wm" ;;
    pacman:i3status)                echo "i3status" ;;
    pacman:polybar)                 echo "polybar" ;;
    pacman:picom)                   echo "picom" ;;
    pacman:sway)                    echo "sway" ;;
    pacman:swaylock)                echo "swaylock" ;;
    pacman:swayidle)                echo "swayidle" ;;
    pacman:waybar)                  echo "waybar" ;;
    pacman:dmenu)                   echo "dmenu" ;;
    pacman:git)                     echo "git" ;;
    pacman:curl)                    echo "curl" ;;

    apt:zsh)                        echo "zsh" ;;
    apt:zsh-autosuggestions)        echo "zsh-autosuggestions" ;;
    apt:zsh-syntax-highlighting)    echo "zsh-syntax-highlighting" ;;
    apt:nerd-font)                  echo "fonts-jetbrains-mono" ;;
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
    apt:dmenu)                      echo "dmenu" ;;
    apt:git)                        echo "git" ;;
    apt:curl)                       echo "curl" ;;

    dnf:zsh)                        echo "zsh" ;;
    dnf:zsh-autosuggestions)        echo "zsh-autosuggestions" ;;
    dnf:zsh-syntax-highlighting)    echo "zsh-syntax-highlighting" ;;
    dnf:nerd-font)                  echo "jetbrains-mono-fonts" ;;
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
    dnf:dmenu)                      echo "dmenu" ;;
    dnf:git)                        echo "git" ;;
    dnf:curl)                       echo "curl" ;;

    zypper:zsh)                     echo "zsh" ;;
    zypper:zsh-autosuggestions)     echo "zsh-autosuggestions" ;;
    zypper:zsh-syntax-highlighting) echo "zsh-syntax-highlighting" ;;
    zypper:nerd-font)               echo "jetbrains-mono-fonts" ;;
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
    zypper:dmenu)                   echo "dmenu" ;;
    zypper:git)                     echo "git" ;;
    zypper:curl)                    echo "curl" ;;

    xbps:zsh)                       echo "zsh" ;;
    xbps:zsh-autosuggestions)       echo "zsh-autosuggestions" ;;
    xbps:zsh-syntax-highlighting)   echo "zsh-syntax-highlighting" ;;
    xbps:nerd-font)                 echo "font-jetbrains-mono-nerd-fonts" ;;
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
    xbps:dmenu)                     echo "dmenu" ;;
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

# ---------- detect display server ----------
DISPLAY_SERVER=""
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  DISPLAY_SERVER="wayland"
  info "Detected Wayland session"
elif [[ -n "${DISPLAY:-}" ]]; then
  DISPLAY_SERVER="x11"
  info "Detected X11 session"
else
  warn "Could not detect display server. Assuming X11."
  DISPLAY_SERVER="x11"
fi

# ---------- choose WM ----------
info "Choose window manager:"
echo "  1) i3 (X11, tiling, keyboard-driven)"
echo "  2) sway (Wayland, tiling, keyboard-driven)"
echo "  3) skip WM (use existing DE)"
read -r -p "Enter choice (1/2/3): " wm_choice

case "$wm_choice" in
  1) WM="i3"; WM_TYPE="x11" ;;
  2) WM="sway"; WM_TYPE="wayland" ;;
  3) WM=""; WM_TYPE="" ;;
  *) err "Invalid choice"; exit 1 ;;
esac

# ---------- 1. update package database ----------
info "Updating package database…"
pm_update

# ---------- 2. base packages ----------
BASE_LOGICAL=(starship fastfetch eza bat zoxide fzf zsh zsh-autosuggestions zsh-syntax-highlighting nerd-font kitty alacritty git curl)

info "Installing base packages…"
for pkg in "${BASE_LOGICAL[@]}"; do
  ensure_pkg "$pkg"
done

# ---------- 3. config dirs ----------
mkdir -p "$HOME/.config/kitty" "$HOME/.config/alacritty" "$HOME/.config/fastfetch" "$HOME/.config/eza"

# ---------- 4. window manager + bar ----------
if [[ -n "$WM" ]]; then
  if [[ "$WM" == "i3" ]]; then
    info "Installing i3 + polybar…"
    for pkg in i3 i3status dmenu polybar picom; do
      ensure_pkg "$pkg"
    done

    mkdir -p "$HOME/.config/i3"
    info "Writing i3 config…"
    cat > "$HOME/.config/i3/config" <<'EOF'
# i3 config — Tokyo Night rice
set $mod Mod4

# Font for window titles
font pango:JetBrainsMono Nerd Font 10

# Colors (Tokyo Night)
set $bg     #1a1b26
set $fg     #c0caf5
set $red    #f7768e
set $green  #9ece6a
set $blue   #7aa2f7

# Window colors
#                   border  background text    indicator
client.focused      $blue   $bg        $fg     $green
client.unfocused    $bg     $bg        $fg     $bg
client.focused_inactive $bg $bg        $fg     $bg
client.urgent       $red    $red       $fg     $red

# Gaps
gaps inner 8
gaps outer 4
smart_gaps on

# Keyboard
bindsym $mod+Return exec kitty
bindsym $mod+d exec dmenu_run -nb "$bg" -nf "$fg" -sb "$blue" -sf "$bg"
bindsym $mod+Shift+q kill
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Layout
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Workspaces
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

# Reload/restart
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart

# Floating
bindsym $mod+Shift+space floating toggle

# Picom compositor
exec_always --no-startup-id picom -b

# Polybar
exec_always --no-startup-id killall -q polybar; polybar main 2>/dev/null || true
EOF
    ok "i3 config created"

    mkdir -p "$HOME/.config/polybar"
    info "Writing polybar config…"
    cat > "$HOME/.config/polybar/config" <<'EOF'
; polybar — Tokyo Night rice
[colors]
background = #1a1b26
foreground = #c0caf5
accent     = #7aa2f7
green      = #9ece6a
yellow     = #e0af68
red        = #f7768e

[bar/main]
monitor = ${env:MONITOR:}
width = 100%
height = 28
fixed-center = true
background = ${colors.background}
foreground = ${colors.foreground}
line-color = ${colors.accent}
border-size = 0
padding-left = 2
padding-right = 2
module-margin-left = 1
module-margin-right = 1
font-0 = JetBrainsMono Nerd Font:pixelsize=10;2
font-1 = JetBrainsMono Nerd Font:pixelsize=16;3

modules-left = i3
modules-center = title
modules-right = cpu memory pulseaudio date

[module/i3]
type = internal/i3
format = <label-state> <label-mode>
index-sort = true
label-mode-padding = 2
label-focused = %icon%
label-focused-background = ${colors.accent}
label-focused-foreground = #000
label-focused-padding = 2
label-unfocused = %icon%
label-unfocused-padding = 2
ws-icon-0 = 1;󰣇
ws-icon-1 = 2;󰈹
ws-icon-2 = 3;󰨞
ws-icon-3 = 4;󰊢
ws-icon-4 = 5;󱇪

[module/title]
type = internal/xwindow
label = %title:0:50:...%

[module/cpu]
type = internal/cpu
interval = 2
label = 󰻠 %percentage%%
label-foreground = ${colors.green}

[module/memory]
type = internal/memory
interval = 2
label = 󰑭 %percentage%%
label-foreground = ${colors.yellow}

[module/pulseaudio]
type = internal/pulseaudio
label-volume = 󰕾 %percentage%%
label-volume-foreground = ${colors.accent}
label-muted = 󰝟 muted
label-muted-foreground = #666

[module/date]
type = internal/date
interval = 1
date = %H:%M:%S
date-alt = %a %d %b %Y
label = 󰃭 %date%
label-foreground = ${colors.accent}
EOF
    ok "polybar config created"

  elif [[ "$WM" == "sway" ]]; then
    info "Installing sway + waybar…"
    for pkg in sway swaylock swayidle waybar dmenu; do
      ensure_pkg "$pkg"
    done

    mkdir -p "$HOME/.config/sway"
    info "Writing sway config…"
    cat > "$HOME/.config/sway/config" <<'EOF'
# sway config — Tokyo Night rice
set $mod Mod4
set $term kitty
set $menu dmenu_run -nb '#1a1b26' -nf '#c0caf5' -sb '#7aa2f7' -sf '#1a1b26'

# Colors
set $bg     #1a1b26
set $fg     #c0caf5
set $blue   #7aa2f7
set $green  #9ece6a
set $red    #f7768e

# Font
font pango:JetBrainsMono Nerd Font 10

# Client colors
client.focused          $blue   $bg $fg $green $blue
client.unfocused        $bg     $bg $fg $bg    $bg
client.focused_inactive $bg     $bg $fg $bg    $bg
client.urgent           $red    $red $fg $red  $red

# Gaps
gaps inner 8
gaps outer 4
smart_gaps on

# Bindings
bindsym $mod+Return exec $term
bindsym $mod+d exec $menu
bindsym $mod+Shift+q kill
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Workspaces
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

# Reload
bindsym $mod+Shift+c reload

# Autolock
exec swayidle -w before-sleep 'swaylock -c 1a1b26'

# Waybar
bar {
  swaybar_command waybar
}
EOF
    ok "sway config created"

    mkdir -p "$HOME/.config/waybar"
    cat > "$HOME/.config/waybar/config" <<'EOF'
{
  "layer": "top",
  "position": "top",
  "height": 28,
  "modules-left": ["sway/workspaces", "sway/mode"],
  "modules-center": ["sway/window"],
  "modules-right": ["cpu", "memory", "pulseaudio", "clock"],

  "sway/workspaces": {
    "format": "{icon}",
    "format-icons": {
      "1": "󰣇",
      "2": "󰈹",
      "3": "󰨞",
      "4": "󰊢",
      "5": "󱇪"
    }
  },
  "cpu":       { "format": "󰻠 {usage}%" },
  "memory":    { "format": "󰑭 {percentage}%" },
  "pulseaudio":{ "format": "󰕾 {volume}%", "format-muted": "󰝟" },
  "clock":     { "format": "󰃭 {:%H:%M:%S}" }
}
EOF

    cat > "$HOME/.config/waybar/style.css" <<'EOF'
* {
  all: unset;
  font-family: "JetBrainsMono Nerd Font", monospace;
  font-size: 12px;
}

window {
  background-color: #1a1b26;
  color: #c0caf5;
}

#workspaces button {
  padding: 0 8px;
  margin: 0 4px;
}

#workspaces button.active {
  background-color: #7aa2f7;
  color: #1a1b26;
  border-radius: 4px;
}

#cpu, #memory, #pulseaudio, #clock {
  padding: 0 10px;
}

#cpu { color: #9ece6a; }
#memory { color: #e0af68; }
#pulseaudio { color: #7aa2f7; }
#clock { color: #7aa2f7; }
EOF
    ok "waybar config created"
  fi
fi

# ---------- 5. picom config (X11) ----------
if [[ "$DISPLAY_SERVER" == "x11" ]]; then
  mkdir -p "$HOME/.config/picom"
  info "Writing picom config…"
  cat > "$HOME/.config/picom/picom.conf" <<'EOF'
# picom — Tokyo Night compositor
backend = "glx";
vsync = true;
mark-wmwin-focused = true;
detect-rounded-corners = true;

# Opacity
active-opacity = 1.0;
inactive-opacity = 0.95;
frame-opacity = 1.0;

# Blur
blur-method = "dual_kawase";
blur-strength = 10;
blur-background = true;

# Fading
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;

# Shadows
shadow = true;
shadow-radius = 8;
shadow-opacity = 0.4;
shadow-offset-x = -8;
shadow-offset-y = -8;
EOF
  ok "picom config created"
fi

# ---------- 6. GTK settings ----------
info "Configuring GTK theme…"
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Tokyo-Night
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=true
EOF
ok "GTK theme configured"

# ---------- 7. starship ----------
info "Writing ~/.config/starship.toml"
cat > "$HOME/.config/starship.toml" <<'EOF'
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
color_blue = '#7aa2f7'
color_green = '#9ece6a'
color_red = '#f7768e'
color_yellow = '#e0af68'

[os]
disabled = false
style = "bg:color_bg0 fg:color_fg0"
[os.symbols]
Linux   = "󰌽 "
Arch    = "󰣇 "
Ubuntu  = " "
Debian  = " "
Fedora  = " "
openSUSE = " "

[username]
show_always = true
style_user = "bg:color_bg0 fg:color_fg0"
style_root = "bg:color_bg0 fg:color_red"
format = '[ $user ]($style)'

[directory]
style = "fg:color_fg0 bg:color_bg1"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = ""
style = "bg:color_bg2"
format = '[ $symbol $branch ]($style)'
[git_status]
style = "bg:color_bg2"
format = '[$all_status$ahead_behind ]($style)'

[nodejs]
symbol = ""
style = "bg:color_bg3"
format = '[ $symbol ($version) ]($style)'
[rust]
symbol = ""
style = "bg:color_bg3"
format = '[ $symbol ($version) ]($style)'
[golang]
symbol = ""
style = "bg:color_bg3"
format = '[ $symbol ($version) ]($style)'
[python]
symbol = ""
style = "bg:color_bg3"
format = '[ $symbol ($version) ]($style)'

[fill]
symbol = " "
[cmd_duration]
min_time = 500
style = "fg:color_yellow"
format = '[  $duration ]($style)'
[character]
success_symbol = '[](bold fg:color_green)'
error_symbol = '[](bold fg:color_red)'
EOF
ok "starship configured"

# ---------- 8. fastfetch ----------
info "Writing ~/.config/fastfetch/config.jsonc"
cat > "$HOME/.config/fastfetch/config.jsonc" <<'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": { "source": "os", "padding": { "top": 1, "right": 3 } },
  "display": { "separator": "  " },
  "modules": [
    "break",
    { "type": "title", "format": "{user-name-colored}{at-symbol-colored}{host-name-colored}" },
    { "type": "separator", "string": "──────────────────────────" },
    { "type": "os",       "key": " OS",     "keyColor": "blue" },
    { "type": "kernel",   "key": "│ ├",    "keyColor": "blue" },
    { "type": "packages", "key": "│ ├󰏖",   "keyColor": "blue" },
    { "type": "shell",    "key": "│ └",    "keyColor": "blue" },
    "break",
    { "type": "wm",           "key": " WM",   "keyColor": "magenta" },
    { "type": "terminal",     "key": "│ ├",  "keyColor": "magenta" },
    { "type": "terminalfont", "key": "│ └",  "keyColor": "magenta" },
    "break",
    { "type": "host",   "key": "󰌢 PC",   "keyColor": "green" },
    { "type": "cpu",    "key": "│ ├󰻠",  "keyColor": "green" },
    { "type": "gpu",    "key": "│ ├󰍛",  "keyColor": "green" },
    { "type": "memory", "key": "│ ├󰑭",  "keyColor": "green" },
    { "type": "disk",   "key": "│ └",   "keyColor": "green" },
    "break",
    { "type": "colors", "paddingLeft": 2, "symbol": "circle" },
    "break"
  ]
}
EOF
ok "fastfetch configured"

# ---------- 9. eza theme ----------
info "Writing ~/.config/eza/theme.yml"
cat > "$HOME/.config/eza/theme.yml" <<'EOF'
colourful: true
filekinds:
  directory:  { foreground: "#7aa2f7" }
  symlink:    { foreground: "#7dcfff" }
  executable: { foreground: "#9ece6a" }
perms:
  user_read:         { foreground: "#c0caf5" }
  user_write:        { foreground: "#e0af68" }
  user_execute_file: { foreground: "#9ece6a" }
size:
  number_byte: { foreground: "#c0caf5" }
  unit_byte:   { foreground: "#565f89" }
git:
  new:      { foreground: "#9ece6a" }
  modified: { foreground: "#e0af68" }
  deleted:  { foreground: "#f7768e" }
EOF
ok "eza theme written"

# ---------- 10. ~/.zshrc ----------
ZSHRC="$HOME/.zshrc"; MARKER="# >>> rice setup (managed) >>>"
[[ -f "$ZSHRC" ]] || touch "$ZSHRC"

if [[ ! -f "$HOME/.zshrc.backup" ]]; then
  cp "$ZSHRC" "$HOME/.zshrc.backup"; ok "Backed up ~/.zshrc"
fi

if ! grep -qF "$MARKER" "$ZSHRC"; then
  info "Resolving zsh plugin paths…"
  AUTOSUGGEST_PATH="$(zsh_plugin_path zsh-autosuggestions)"
  HIGHLIGHT_PATH="$(zsh_plugin_path zsh-syntax-highlighting)"
  [[ -z "$AUTOSUGGEST_PATH" ]] && warn "zsh-autosuggestions path not found"
  [[ -z "$HIGHLIGHT_PATH"   ]] && warn "zsh-syntax-highlighting path not found"

  cat >> "$ZSHRC" <<EOF

$MARKER
eval "\$(starship init zsh)"
eval "\$(zoxide init zsh)"
source <(fzf --zsh)
export FZF_DEFAULT_OPTS=" \\
  --color=bg+:#283457,bg:#16161e,border:#27a1b9,spinner:#ff007c \\
  --color=hl:#2ac3de,fg:#c0caf5,header:#ff9e64,info:#545c7e \\
  --color=pointer:#ff007c,marker:#ff007c,fg+:#c0caf5,prompt:#2ac3de \\
  --color=hl+:#2ac3de,query:#c0caf5:regular --layout=reverse --border=rounded"

alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first --git'
alias la='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons --group-directories-first'
alias cat='bat --paging=never'

${AUTOSUGGEST_PATH:+source "$AUTOSUGGEST_PATH"}
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'
${HIGHLIGHT_PATH:+source "$HIGHLIGHT_PATH"}

if [[ -o interactive ]]; then fastfetch; fi
# <<< rice setup (managed) <<<
EOF
  ok "~/.zshrc updated"
fi

# ---------- 11. final ----------
cat <<'EOF'

──────────────────────────────────────────────
  ✅  Linux rice installed!
──────────────────────────────────────────────
EOF

if [[ -n "$WM" ]]; then
  cat <<EOF
 Window Manager: $WM
 Configs saved to ~/.config/$WM/

 To start your WM:
   - Add to ~/.xinitrc (X11):   exec $WM
   - Select in login screen (Wayland)

EOF
fi

cat <<'EOF'
 Next steps:
  1. Reload shell: exec zsh
  2. Edit configs in ~/.config/ (starship, kitty, i3/sway, etc)
  3. Set terminal: kitty or alacritty
  4. Restart to apply theme changes

 Keybindings (i3/sway):
  • Super+Enter — open terminal
  • Super+D — application menu
  • Super+1-5 — switch workspace
  • Super+Shift+Q — close window
  • Arrow keys — navigate windows

──────────────────────────────────────────────
EOF
ok "Done!"
