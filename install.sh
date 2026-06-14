#!/usr/bin/env bash
# install.sh — Tokyo Night terminal rice for macOS (zsh + Ghostty)
#
# Turns a bare macOS/zsh terminal into an r/unixporn-style "rice":
#   starship · fastfetch · eza · bat · zoxide · fzf · zsh plugins · Ghostty · Nerd Font
#
# Safe & idempotent: re-running never duplicates ~/.zshrc lines and overwrites
# configs in place. Backs up ~/.zshrc to ~/.zshrc.backup before touching it.
# No sudo required.
set -euo pipefail

# ---------- pretty logging ----------
c_blue=$'\033[34m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_red=$'\033[31m'; c_rst=$'\033[0m'
info() { printf "%s==>%s %s\n" "$c_blue" "$c_rst" "$*"; }
ok()   { printf "%s ✓%s %s\n" "$c_grn" "$c_rst" "$*"; }
warn() { printf "%s !%s %s\n" "$c_yel" "$c_rst" "$*"; }
err()  { printf "%s ✗%s %s\n" "$c_red" "$c_rst" "$*" >&2; }

# ---------- 0. sanity ----------
[[ "$(uname)" == "Darwin" ]] || { err "This script targets macOS."; exit 1; }

# ---------- 1. Homebrew ----------
if ! command -v brew >/dev/null 2>&1; then
  info "Homebrew not found — installing…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Load brew into this session regardless of CPU arch.
if   [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew    ]]; then eval "$(/usr/local/bin/brew shellenv)"
else err "brew still not on PATH after install."; exit 1; fi
BREW_PREFIX="$(brew --prefix)"
ok "Homebrew ready at $BREW_PREFIX"

# ---------- 2. packages ----------
FORMULAE=(starship fastfetch eza bat zoxide fzf zsh-autosuggestions zsh-syntax-highlighting)
info "Installing CLI tools…"
for f in "${FORMULAE[@]}"; do
  if brew list --formula "$f" >/dev/null 2>&1; then ok "$f already installed"
  else info "brew install $f"; brew install "$f"; fi
done

info "Installing Ghostty + JetBrainsMono Nerd Font (casks)…"
for cask in ghostty font-jetbrains-mono-nerd-font; do
  if brew list --cask "$cask" >/dev/null 2>&1; then ok "$cask already installed"
  else info "brew install --cask $cask"; brew install --cask "$cask"; fi
done

# ---------- 3. config dirs ----------
mkdir -p "$HOME/.config/ghostty" "$HOME/.config/fastfetch" "$HOME/.config/eza"

# ---------- 4. Ghostty (Tokyo Night built-in theme + Nerd Font) ----------
info "Writing ~/.config/ghostty/config"
cat > "$HOME/.config/ghostty/config" <<'EOF'
# Ghostty — Tokyo Night rice
theme = tokyonight
font-family = "JetBrainsMono Nerd Font"
font-size = 14
background-opacity = 0.95
background-blur-radius = 20
window-padding-x = 14
window-padding-y = 14
window-padding-balance = true
cursor-style = block
cursor-style-blink = true
mouse-hide-while-typing = true
macos-titlebar-style = transparent
macos-option-as-alt = true
EOF
ok "Ghostty configured"

# ---------- 5. starship (Tokyo Night palette, two-line powerline) ----------
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
Macos = "󰀵"

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

# ---------- 6. fastfetch ----------
info "Writing ~/.config/fastfetch/config.jsonc"
cat > "$HOME/.config/fastfetch/config.jsonc" <<'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": { "source": "macos", "padding": { "top": 1, "right": 3 } },
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

# ---------- 7. eza theme ----------
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

# ---------- 8. bat (Tokyo Night tmTheme + config) ----------
BAT_CFG_DIR="$(bat --config-dir)"
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

# ---------- 9. ~/.zshrc (backup + idempotent managed block) ----------
ZSHRC="$HOME/.zshrc"; MARKER="# >>> rice setup (managed) >>>"
[[ -f "$ZSHRC" ]] || touch "$ZSHRC"

# Back up only once so a second run can't clobber the pristine original.
if [[ ! -f "$HOME/.zshrc.backup" ]]; then
  cp "$ZSHRC" "$HOME/.zshrc.backup"; ok "Backed up ~/.zshrc -> ~/.zshrc.backup"
else
  warn "~/.zshrc.backup already exists — keeping original backup"
fi

if grep -qF "$MARKER" "$ZSHRC"; then
  ok "~/.zshrc already contains rice block — not duplicating"
else
  info "Appending managed block to ~/.zshrc"
  # Unquoted heredoc so $BREW_PREFIX expands now; runtime $(...) are escaped as \$(...).
  cat >> "$ZSHRC" <<EOF

$MARKER
# Homebrew
eval "\$($BREW_PREFIX/bin/brew shellenv)"

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
source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'
source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# fastfetch greeting on interactive shells
if [[ -o interactive ]]; then fastfetch; fi
# <<< rice setup (managed) <<<
EOF
  ok "~/.zshrc updated"
fi

# ---------- 10. final instructions ----------
cat <<'EOF'

──────────────────────────────────────────────
 ✅  Rice installed. Manual steps remaining:
──────────────────────────────────────────────
 1. Open the new Ghostty app (Spotlight → "Ghostty").
    Theme + JetBrainsMono Nerd Font are already applied via
    ~/.config/ghostty/config — nothing to click.
 2. (Optional) Make Ghostty your default terminal and pin it to the Dock.
 3. Reload your shell:   exec zsh      (or just open a new Ghostty tab)
 4. First run only: zoxide learns dirs as you `cd` around (then use `z <name>`).

 Notes:
  • Your old prompt (PS1 lines) is still in ~/.zshrc but starship overrides
    it at runtime — remove them if you like. Original at ~/.zshrc.backup.
  • If icons look like boxes in some other terminal, that terminal still
    needs the "JetBrainsMono Nerd Font" set manually in its settings.
──────────────────────────────────────────────
EOF
ok "Done."
