#!/usr/bin/env bash
# install-archlinux.sh — Tokyo Night terminal rice for Linux (zsh + kitty/alacritty)
#
# Turns a bare Linux/zsh terminal into an r/unixporn-style "rice":
#   starship · fastfetch · eza · bat · zoxide · fzf · zsh plugins · kitty · Nerd Font
#
# Supports: Arch/Manjaro (pacman) · Debian/Ubuntu/Mint (apt) ·
#           Fedora/RHEL (dnf) · openSUSE (zypper) · Void Linux (xbps)
#
# Safe & idempotent: re-running never duplicates ~/.zshrc lines and overwrites
# configs in place. Backs up ~/.zshrc to ~/.zshrc.backup before touching it.
# Requires sudo for package installation.
set -euo pipefail

# ---------- pretty logging ----------
c_blue=$'\033[34m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_red=$'\033[31m'; c_rst=$'\033[0m'
info() { printf "%s==>%s %s\n" "$c_blue" "$c_rst" "$*"; }
ok()   { printf "%s ✓%s %s\n" "$c_grn" "$c_rst" "$*"; }
warn() { printf "%s !%s %s\n" "$c_yel" "$c_rst" "$*"; }
err()  { printf "%s ✗%s %s\n" "$c_red" "$c_rst" "$*" >&2; }

# ---------- 0. sanity ----------
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
    pacman)        pacman -Q "$1"    >/dev/null 2>&1 ;;
    apt)           dpkg -s "$1"      >/dev/null 2>&1 ;;
    dnf|zypper)    rpm -q "$1"       >/dev/null 2>&1 ;;
    xbps)          xbps-query "$1"   >/dev/null 2>&1 ;;
  esac
}

# Map logical names → real package names per PM
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

    apt:zsh)                        echo "zsh" ;;
    apt:zsh-autosuggestions)        echo "zsh-autosuggestions" ;;
    apt:zsh-syntax-highlighting)    echo "zsh-syntax-highlighting" ;;
    apt:nerd-font)                  echo "fonts-jetbrains-mono" ;;
    apt:eza)                        echo "eza" ;;
    apt:bat)                        echo "bat" ;;
    apt:fzf)                        echo "fzf" ;;
    apt:zoxide)                     echo "" ;;  # universal installer
    apt:fastfetch)                  echo "" ;;  # universal installer
    apt:starship)                   echo "" ;;  # universal installer
    apt:kitty)                      echo "kitty" ;;
    apt:alacritty)                  echo "alacritty" ;;

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

    *) echo "$1" ;;  # pass through as fallback
  esac
}

# Install a logical package; use universal installer when distro has no pkg
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

# Resolve zsh plugin source path (differs by distro)
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

# ---------- 1. update package database ----------
info "Updating package database…"
pm_update

# ---------- 2. packages ----------
LOGICAL_PKGS=(starship fastfetch eza bat zoxide fzf zsh zsh-autosuggestions zsh-syntax-highlighting nerd-font)
info "Installing CLI tools and fonts…"
for pkg in "${LOGICAL_PKGS[@]}"; do
  ensure_pkg "$pkg"
done

# Ask user which terminal to install
info "Choose a terminal emulator:"
echo "  1) kitty (recommended — native wayland support)"
echo "  2) alacritty (GPU-accelerated, minimal)"
echo "  3) skip terminal (use default)"
read -r -p "Enter choice (1/2/3): " terminal_choice

case "$terminal_choice" in
  1)
    ensure_pkg "kitty"
    TERMINAL_CONFIG="kitty"
    ;;
  2)
    ensure_pkg "alacritty"
    TERMINAL_CONFIG="alacritty"
    ;;
  3)
    warn "Skipping terminal installation"
    TERMINAL_CONFIG=""
    ;;
  *)
    err "Invalid choice"
    exit 1
    ;;
esac

# ---------- 3. config dirs ----------
mkdir -p "$HOME/.config/kitty" "$HOME/.config/alacritty" "$HOME/.config/fastfetch" "$HOME/.config/eza"

# ---------- 4. kitty config (Tokyo Night + JetBrainsMono Nerd) ----------
if [[ "$TERMINAL_CONFIG" == "kitty" ]]; then
  info "Writing ~/.config/kitty/kitty.conf"
  cat > "$HOME/.config/kitty/kitty.conf" <<'EOF'
# kitty — Tokyo Night rice
include ~/.config/kitty/tokyonight.conf

font_family JetBrainsMono Nerd Font
font_size 12
background_opacity 0.95
background_blur 20
window_padding_width 10
cursor_shape block
cursor_blink_interval 0.5
enable_audio_bell no
EOF
  ok "kitty configured"

  info "Fetching kitty Tokyo Night theme…"
  if curl -fsSL "https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/kitty/tokyonight_night.conf" \
    -o "$HOME/.config/kitty/tokyonight.conf"; then
    ok "kitty Tokyo Night theme installed"
  else
    warn "Could not fetch Tokyo Night theme; using default"
  fi
fi

# ---------- 5. alacritty config (Tokyo Night + JetBrainsMono Nerd) ----------
if [[ "$TERMINAL_CONFIG" == "alacritty" ]]; then
  info "Writing ~/.config/alacritty/alacritty.toml"
  cat > "$HOME/.config/alacritty/alacritty.toml" <<'EOF'
# alacritty — Tokyo Night rice
[window]
opacity = 0.95
padding = { x = 10, y = 10 }

[font]
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
size = 12

[colors.primary]
background = "#1a1b26"
foreground = "#c0caf5"

[colors.normal]
black   = "#16161e"
red     = "#f7768e"
green   = "#9ece6a"
yellow  = "#e0af68"
blue    = "#7aa2f7"
magenta = "#bb9af7"
cyan    = "#7dcfff"
white   = "#c0caf5"

[colors.bright]
black   = "#414868"
red     = "#f7768e"
green   = "#9ece6a"
yellow  = "#e0af68"
blue    = "#7aa2f7"
magenta = "#bb9af7"
cyan    = "#7dcfff"
white   = "#c0caf5"

[cursor]
style = { shape = "Block", blinking = "On" }

[bell]
animation = "None"
EOF
  ok "alacritty configured"
fi

# ---------- 6. starship (Tokyo Night palette, two-line powerline) ----------
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
[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = "󰝚 "
"Pictures" = " "
"Developer" = "󰲋 "

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

# ---------- 7. fastfetch ----------
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

# ---------- 8. eza theme ----------
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

# ---------- 9. bat (Tokyo Night tmTheme + config) ----------
BAT_CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bat"
mkdir -p "$BAT_CFG_DIR/themes"
BAT_THEME_NAME="tokyonight_night"
info "Fetching bat Tokyo Night theme…"
if curl -fsSL \
   "https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme" \
   -o "$BAT_CFG_DIR/themes/tokyonight_night.tmTheme"; then
  bat cache --build >/dev/null 2>&1 || true
  ok "bat Tokyo Night theme installed"
else
  warn "Could not fetch Tokyo Night theme; falling back to built-in 'TwoDark'"
  BAT_THEME_NAME="TwoDark"
fi
printf -- '--theme="%s"\n--style="numbers,changes,header"\n' "$BAT_THEME_NAME" > "$BAT_CFG_DIR/config"
ok "bat configured ($BAT_THEME_NAME)"

# ---------- 10. ~/.zshrc (backup + idempotent managed block) ----------
ZSHRC="$HOME/.zshrc"; MARKER="# >>> rice setup (managed) >>>"
[[ -f "$ZSHRC" ]] || touch "$ZSHRC"

if [[ ! -f "$HOME/.zshrc.backup" ]]; then
  cp "$ZSHRC" "$HOME/.zshrc.backup"; ok "Backed up ~/.zshrc -> ~/.zshrc.backup"
else
  warn "~/.zshrc.backup already exists — keeping original backup"
fi

if grep -qF "$MARKER" "$ZSHRC"; then
  ok "~/.zshrc already contains rice block — not duplicating"
else
  info "Resolving zsh plugin paths…"
  AUTOSUGGEST_PATH="$(zsh_plugin_path zsh-autosuggestions)"
  HIGHLIGHT_PATH="$(zsh_plugin_path zsh-syntax-highlighting)"
  [[ -z "$AUTOSUGGEST_PATH" ]] && warn "zsh-autosuggestions path not found — plugin may not load"
  [[ -z "$HIGHLIGHT_PATH"   ]] && warn "zsh-syntax-highlighting path not found — plugin may not load"

  info "Appending managed block to ~/.zshrc"
  cat >> "$ZSHRC" <<EOF

$MARKER
# Starship prompt
eval "\$(starship init zsh)"

# zoxide — smart cd
eval "\$(zoxide init zsh)"

# fzf — fuzzy finder (key bindings + completion)
source <(fzf --zsh)
export FZF_DEFAULT_OPTS=" \\
  --color=bg+:#283457,bg:#16161e,border:#27a1b9,spinner:#ff007c \\
  --color=hl:#2ac3de,fg:#c0caf5,header:#ff9e64,info:#545c7e \\
  --color=pointer:#ff007c,marker:#ff007c,fg+:#c0caf5,prompt:#2ac3de \\
  --color=hl+:#2ac3de,query:#c0caf5:regular --layout=reverse --border=rounded"

# eza — modern ls with icons
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first --git'
alias la='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons --group-directories-first'

# bat — better cat
alias cat='bat --paging=never'

# zsh plugins (syntax-highlighting MUST be sourced last)
${AUTOSUGGEST_PATH:+source "$AUTOSUGGEST_PATH"}
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'
${HIGHLIGHT_PATH:+source "$HIGHLIGHT_PATH"}

# fastfetch greeting on interactive shells
if [[ -o interactive ]]; then fastfetch; fi
# <<< rice setup (managed) <<<
EOF
  ok "~/.zshrc updated"
fi

# ---------- 11. final instructions ----------
cat <<'EOF'

──────────────────────────────────────────────
  ✅  Rice installed. Manual steps remaining:
──────────────────────────────────────────────
  1. Set your terminal as default (if not already):
     • kitty users: already configured
     • alacritty users: set in your DE settings
  2. (Optional) Add JetBrainsMono Nerd Font to your DE's font settings
  3. Reload your shell:   exec zsh      (or just open a new terminal)
  4. First run only: zoxide learns dirs as you `cd` around (then use `z <name>`)

  Notes:
   • Your old prompt (PS1 lines) are still in ~/.zshrc but starship overrides
     it at runtime — remove them if you like. Original at ~/.zshrc.backup.
   • If icons look like boxes, verify JetBrainsMono Nerd Font is installed
     and set in your terminal.
──────────────────────────────────────────────
EOF
ok "Done."
