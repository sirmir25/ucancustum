#!/usr/bin/env bash
# install-dwm.sh — Interactive DWM builder & configurator
#
# Guides you through 9 questions, then builds DWM from source (dwm-flexipatch)
# with your exact preferences: color scheme · patches · bar · terminal · font
#
# Distros: Arch/Manjaro (pacman) · Debian/Ubuntu (apt) ·
#          Fedora/RHEL (dnf) · openSUSE (zypper) · Void Linux (xbps)
#
set -euo pipefail

# ── colors ────────────────────────────────────────────────────────────────────
c_blue=$'\033[34m'; c_cyan=$'\033[36m'; c_grn=$'\033[32m'
c_yel=$'\033[33m';  c_red=$'\033[31m';  c_mag=$'\033[35m'
c_bold=$'\033[1m';  c_dim=$'\033[2m';   c_rst=$'\033[0m'

info() { printf "%s==>%s %s\n"  "$c_blue" "$c_rst" "$*"; }
ok()   { printf "%s ✓%s %s\n"   "$c_grn"  "$c_rst" "$*"; }
warn() { printf "%s !%s %s\n"   "$c_yel"  "$c_rst" "$*"; }
err()  { printf "%s ✗%s %s\n"   "$c_red"  "$c_rst" "$*" >&2; }

header() {
  printf "\n%s┌──────────────────────────────────────────────────┐%s\n" "$c_cyan" "$c_rst"
  printf "%s│%s  %s%-48s%s%s│%s\n" "$c_cyan" "$c_rst" "$c_bold" "$*" "$c_rst" "$c_cyan" "$c_rst"
  printf "%s└──────────────────────────────────────────────────┘%s\n\n" "$c_cyan" "$c_rst"
}

step() {
  printf "\n%s● [%s/%s]%s %s%s%s\n" "$c_mag" "$1" "$2" "$c_rst" "$c_bold" "$3" "$c_rst"
  printf "%s  ────────────────────────────────────────%s\n\n" "$c_dim" "$c_rst"
}

# ── sanity ────────────────────────────────────────────────────────────────────
[[ "$(uname)" == "Linux" ]] || { err "This script targets Linux only."; exit 1; }

# ── package manager ───────────────────────────────────────────────────────────
detect_pm() {
  if   command -v pacman       >/dev/null 2>&1; then PM="pacman"
  elif command -v apt-get      >/dev/null 2>&1; then PM="apt"
  elif command -v dnf          >/dev/null 2>&1; then PM="dnf"
  elif command -v zypper       >/dev/null 2>&1; then PM="zypper"
  elif command -v xbps-install >/dev/null 2>&1; then PM="xbps"
  else err "No supported package manager (pacman/apt/dnf/zypper/xbps)."; exit 1
  fi
}

pm_install() {
  case "$PM" in
    pacman) sudo pacman -S --noconfirm --needed "$@" ;;
    apt)    sudo apt-get install -y "$@" ;;
    dnf)    sudo dnf install -y "$@" ;;
    zypper) sudo zypper install -y "$@" ;;
    xbps)   sudo xbps-install -y "$@" ;;
  esac
}

install_build_deps() {
  info "Installing build dependencies…"
  case "$PM" in
    pacman) pm_install base-devel libx11 libxft libxinerama ;;
    apt)    pm_install build-essential libx11-dev libxft-dev libxinerama-dev ;;
    dnf)    pm_install gcc make libX11-devel libXft-devel libXinerama-devel ;;
    zypper) pm_install gcc make libX11-devel libXft-devel libXinerama-devel ;;
    xbps)   pm_install base-devel libX11-devel libXft-devel libXinerama-devel ;;
  esac
  pm_install git curl feh
  ok "Build dependencies ready"
}

install_pkg() {
  local name="$1"
  info "Installing ${name}…"
  case "$PM" in
    pacman) sudo pacman -S --noconfirm --needed "$name" ;;
    apt)    sudo apt-get install -y "$name" ;;
    dnf)    sudo dnf install -y "$name" ;;
    zypper) sudo zypper install -y "$name" ;;
    xbps)   sudo xbps-install -y "$name" ;;
  esac
  ok "$name installed"
}

# ── interactive helpers ───────────────────────────────────────────────────────
LAST_CHOICE=""
LAST_YESNO=""

# ask_choice <question> <opt1> <opt2> ...
# Sets LAST_CHOICE to the 1-based index selected
ask_choice() {
  local question="$1"; shift
  local opts=("$@")
  local n="${#opts[@]}"

  printf "%s%s%s\n" "$c_bold" "$question" "$c_rst"
  local i
  for i in "${!opts[@]}"; do
    printf "  %s%d)%s  %s\n" "$c_cyan" "$((i+1))" "$c_rst" "${opts[$i]}"
  done
  printf "\n"

  while true; do
    read -r -p "  Choice [1-${n}]: " LAST_CHOICE
    if [[ "$LAST_CHOICE" =~ ^[0-9]+$ ]] && (( LAST_CHOICE >= 1 && LAST_CHOICE <= n )); then
      return 0
    fi
    printf "  %sPlease enter a number between 1 and %d%s\n" "$c_yel" "$n" "$c_rst"
  done
}

# ask_yesno <question>
# Sets LAST_YESNO to "y" or "n"
ask_yesno() {
  printf "%s%s%s " "$c_bold" "$1" "$c_rst"
  printf "%s[y/n]%s: " "$c_cyan" "$c_rst"
  while true; do
    read -r LAST_YESNO
    case "${LAST_YESNO,,}" in
      y|yes) LAST_YESNO="y"; return ;;
      n|no)  LAST_YESNO="n"; return ;;
      *) printf "  Please answer %sy%s or %sn%s: " "$c_grn" "$c_rst" "$c_red" "$c_rst" ;;
    esac
  done
}

# ask_multi <question> <opt1> <opt2> ...
# Sets MULTI array: MULTI[i]="1" if selected, "0" otherwise
MULTI=()
ask_multi() {
  local question="$1"; shift
  local opts=("$@")
  local n="${#opts[@]}"
  MULTI=()
  local i
  for i in "${!opts[@]}"; do
    MULTI+=("0")
  done

  printf "%s%s%s\n" "$c_bold" "$question" "$c_rst"
  for i in "${!opts[@]}"; do
    printf "  %s%d)%s  %s\n" "$c_cyan" "$((i+1))" "$c_rst" "${opts[$i]}"
  done
  printf "\n"
  printf "  %sEnter numbers separated by spaces (e.g. 1 3 5) — or press Enter for none:%s\n" "$c_dim" "$c_rst"
  printf "  > "

  local input num
  read -r input
  for num in $input; do
    if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= n )); then
      MULTI[$((num-1))]="1"
    fi
  done
}

# ── WIZARD ────────────────────────────────────────────────────────────────────
clear
printf "%s" "$c_bold$c_cyan"
cat << 'BANNER'
  ╔════════════════════════════════════════════════════════╗
  ║         DWM  Interactive  Setup  Wizard  v2.0         ║
  ║    Dynamic Window Manager — built from source, yours  ║
  ╚════════════════════════════════════════════════════════╝
BANNER
printf "%s\n" "$c_rst"
printf "  Answer %s10 questions%s and DWM will be compiled just for you.\n\n" "$c_bold" "$c_rst"
read -r -p "  Press Enter to start the wizard..."

# ─────────────────────────────────────────────────────────
# Q1 — Color Scheme
# ─────────────────────────────────────────────────────────
clear
header "Q 1 / 10  —  COLOR SCHEME"
ask_choice "Which color palette do you want?" \
  "Tokyo Night   dark blue/purple (recommended)" \
  "Gruvbox       warm brown/orange" \
  "Catppuccin    pastel purple/pink" \
  "Nord          cold arctic blues"

COLOR_CHOICE="$LAST_CHOICE"
case "$COLOR_CHOICE" in
  1)
    COL_BG="#1a1b26"; COL_FG="#c0caf5"; COL_ACCENT="#7aa2f7"
    COL_GREEN="#9ece6a"; COL_RED="#f7768e"; COL_YELLOW="#e0af68"
    COL_BGSEC="#24283b"; COL_BGTER="#414868"; COL_CYAN="#7dcfff"
    SCHEME_NAME="Tokyo Night"
    ;;
  2)
    COL_BG="#282828"; COL_FG="#ebdbb2"; COL_ACCENT="#458588"
    COL_GREEN="#98971a"; COL_RED="#cc241d"; COL_YELLOW="#d79921"
    COL_BGSEC="#3c3836"; COL_BGTER="#504945"; COL_CYAN="#689d6a"
    SCHEME_NAME="Gruvbox"
    ;;
  3)
    COL_BG="#1e1e2e"; COL_FG="#cdd6f4"; COL_ACCENT="#89b4fa"
    COL_GREEN="#a6e3a1"; COL_RED="#f38ba8"; COL_YELLOW="#f9e2af"
    COL_BGSEC="#181825"; COL_BGTER="#313244"; COL_CYAN="#89dceb"
    SCHEME_NAME="Catppuccin Mocha"
    ;;
  4)
    COL_BG="#2e3440"; COL_FG="#eceff4"; COL_ACCENT="#81a1c1"
    COL_GREEN="#a3be8c"; COL_RED="#bf616a"; COL_YELLOW="#ebcb8b"
    COL_BGSEC="#3b4252"; COL_BGTER="#434c5e"; COL_CYAN="#88c0d0"
    SCHEME_NAME="Nord"
    ;;
esac
ok "Scheme: $SCHEME_NAME"

# ─────────────────────────────────────────────────────────
# Q2 — Status Bar
# ─────────────────────────────────────────────────────────
clear
header "Q 2 / 10  —  STATUS BAR"
ask_choice "Which status bar do you want?" \
  "slstatus      tiny C program, very fast — from suckless (recommended)" \
  "dwmblocks     modular, each block is its own shell script" \
  "Built-in bar  simplest option, drive with xsetroot or a shell loop"

BAR_CHOICE="$LAST_CHOICE"
case "$BAR_CHOICE" in
  1) BAR_NAME="slstatus" ;;
  2) BAR_NAME="dwmblocks" ;;
  3) BAR_NAME="builtin" ;;
esac
ok "Bar: $BAR_NAME"

# ─────────────────────────────────────────────────────────
# Q3 — Patches
# ─────────────────────────────────────────────────────────
clear
header "Q 3 / 10  —  PATCHES  (pick as many as you want)"
PATCH_OPTS=(
  "Gaps            adds inner/outer gaps between windows"
  "Systray         system tray in the bar (audio, network, etc.)"
  "Pertag          each tag remembers its own layout independently"
  "Fullscreen      proper F11 fullscreen for any app"
  "Autostart       run programs automatically when DWM starts"
  "No-border       hide window border when only one window is visible"
  "CenteredMaster  extra layout: master window centered, stacks on sides"
)
ask_multi "Which patches do you want?" "${PATCH_OPTS[@]}"

USE_GAPS="${MULTI[0]}"
USE_SYSTRAY="${MULTI[1]}"
USE_PERTAG="${MULTI[2]}"
USE_FULLSCREEN="${MULTI[3]}"
USE_AUTOSTART="${MULTI[4]}"
USE_NOBORDER="${MULTI[5]}"
USE_CMASTER="${MULTI[6]}"

ok "Patches configured"

# ─────────────────────────────────────────────────────────
# Q4 — Gap size (only if gaps chosen)
# ─────────────────────────────────────────────────────────
GAP_SIZE=8
if [[ "$USE_GAPS" == "1" ]]; then
  clear
  header "Q 4 / 10  —  GAP SIZE"
  ask_choice "How large should the gaps be?" \
    "Small   4px  (minimal, almost invisible)" \
    "Medium  8px  (balanced — recommended)" \
    "Large   16px (airy, lots of breathing room)" \
    "Custom  enter your own value"

  case "$LAST_CHOICE" in
    1) GAP_SIZE=4 ;;
    2) GAP_SIZE=8 ;;
    3) GAP_SIZE=16 ;;
    4)
      while true; do
        read -r -p "  Gap size in pixels: " GAP_SIZE
        [[ "$GAP_SIZE" =~ ^[0-9]+$ ]] && break
        warn "Enter a positive integer"
      done
      ;;
  esac
  ok "Gap size: ${GAP_SIZE}px"
else
  printf "\n  %s(Q4 skipped — gaps patch not selected)%s\n" "$c_dim" "$c_rst"
fi

# ─────────────────────────────────────────────────────────
# Q5 — Terminal
# ─────────────────────────────────────────────────────────
clear
header "Q 5 / 10  —  TERMINAL EMULATOR"
ask_choice "Which terminal do you prefer?" \
  "kitty      GPU-accelerated, feature-rich, great Wayland support (recommended)" \
  "alacritty  Rust-based, minimal, blazing fast" \
  "st         suckless terminal — ultra-minimal, built from source"

TERM_CHOICE="$LAST_CHOICE"
case "$TERM_CHOICE" in
  1) TERM_CMD="kitty";     TERM_PKG="kitty" ;;
  2) TERM_CMD="alacritty"; TERM_PKG="alacritty" ;;
  3) TERM_CMD="st";        TERM_PKG="_build_st" ;;
esac
ok "Terminal: $TERM_CMD"

# ─────────────────────────────────────────────────────────
# Q6 — App Launcher
# ─────────────────────────────────────────────────────────
clear
header "Q 6 / 10  —  APP LAUNCHER"
ask_choice "Which launcher do you want?" \
  "dmenu   suckless minimal launcher — default DWM choice" \
  "rofi    modern feature-rich launcher with icons and themes"

LAUNCHER_CHOICE="$LAST_CHOICE"
case "$LAUNCHER_CHOICE" in
  1) LAUNCHER_PKG="dmenu";   LAUNCH_ARRAY='"dmenu_run", NULL' ;;
  2) LAUNCHER_PKG="rofi";    LAUNCH_ARRAY='"rofi", "-show", "drun", NULL' ;;
esac
ok "Launcher: $LAUNCHER_PKG"

# ─────────────────────────────────────────────────────────
# Q7 — Compositor
# ─────────────────────────────────────────────────────────
clear
header "Q 7 / 10  —  COMPOSITOR (picom)"
ask_yesno "Install picom? (enables transparency, blur, drop shadows, smooth fade)"
USE_PICOM="$LAST_YESNO"

PICOM_STYLE=0
if [[ "$USE_PICOM" == "y" ]]; then
  printf "\n"
  ask_choice "Which picom style?" \
    "Minimal    shadows + fade only (stable on any GPU)" \
    "Frosted    blur behind transparent windows (requires modern GPU)" \
    "Disabled   install but don't autostart (configure manually later)"
  PICOM_STYLE="$LAST_CHOICE"
  ok "picom style: $PICOM_STYLE"
else
  ok "Compositor: none"
fi

# ─────────────────────────────────────────────────────────
# Q8 — Font
# ─────────────────────────────────────────────────────────
clear
header "Q 8 / 10  —  BAR FONT"
ask_choice "Which Nerd Font for the DWM bar?" \
  "JetBrains Mono  size 10  (recommended — superb readability + icons)" \
  "FiraCode        size 10  (coding ligatures + icons)" \
  "Hack            size 10  (clean, highly legible)"

FONT_CHOICE="$LAST_CHOICE"
case "$FONT_CHOICE" in
  1) DWM_FONT="JetBrainsMono Nerd Font:size=10" ;;
  2) DWM_FONT="FiraCode Nerd Font:size=10" ;;
  3) DWM_FONT="Hack Nerd Font:size=10" ;;
esac
ok "Font: $DWM_FONT"

# ─────────────────────────────────────────────────────────
# Q9 — Number of Workspaces (Tags)
# ─────────────────────────────────────────────────────────
clear
header "Q 9 / 10  —  WORKSPACES (TAGS)"
ask_choice "How many workspaces do you want?" \
  "5  minimal, uncluttered" \
  "9  standard power-user setup (recommended)" \
  "6  balanced middle ground"

TAGS_CHOICE="$LAST_CHOICE"
case "$TAGS_CHOICE" in
  1) NUM_TAGS=5 ;;
  2) NUM_TAGS=9 ;;
  3) NUM_TAGS=6 ;;
esac
ok "Workspaces: $NUM_TAGS"

# ─────────────────────────────────────────────────────────
# Q10 — Monitor Setup
# ─────────────────────────────────────────────────────────
clear
header "Q 10 / 10  —  MONITOR SETUP"

MONITOR_LIST=()
MONITOR_PRIMARY=""
MONITOR_ARRANGEMENT="right-of"
MONITOR_MODES=()
MONITOR_RATES=()
DETECTED_MONITORS=()
HAS_X=false
MONITOR_SUMMARY=""

# Detect monitors if X is running
if command -v xrandr >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
  HAS_X=true
  mapfile -t DETECTED_MONITORS < <(xrandr --query | awk '/connected/{print $1}')
fi

if [[ "$HAS_X" == "true" ]] && [[ "${#DETECTED_MONITORS[@]}" -gt 0 ]]; then
  # ── Auto-detect mode ──────────────────────────────────
  printf "%sDetected monitors (xrandr):%s\n\n" "$c_bold" "$c_rst"
  local_i=0
  for mon in "${DETECTED_MONITORS[@]}"; do
    local_i=$((local_i+1))
    native=$(xrandr --query | awk -v m="$mon" \
      'BEGIN{found=0} /^'"$mon"' /{found=1;next} found&&/^\s+/{print $1;exit}')
    printf "  %s%d)%s  %s  %s%s%s\n" "$c_cyan" "$local_i" "$c_rst" "$mon" "$c_dim" "${native:-unknown}" "$c_rst"
  done
  printf "\n"

  if [[ "${#DETECTED_MONITORS[@]}" -eq 1 ]]; then
    MONITOR_LIST=("${DETECTED_MONITORS[@]}")
    printf "  %sOnly one monitor detected — using it.%s\n" "$c_dim" "$c_rst"
  else
    ask_choice "Which monitors do you want to use?" \
      "All detected (${DETECTED_MONITORS[*]})" \
      "Only the first one (${DETECTED_MONITORS[0]})" \
      "Choose manually"

    case "$LAST_CHOICE" in
      1) MONITOR_LIST=("${DETECTED_MONITORS[@]}") ;;
      2) MONITOR_LIST=("${DETECTED_MONITORS[0]}") ;;
      3)
        ask_multi "Select monitors to use:" "${DETECTED_MONITORS[@]}"
        for idx in "${!MULTI[@]}"; do
          [[ "${MULTI[$idx]}" == "1" ]] && MONITOR_LIST+=("${DETECTED_MONITORS[$idx]}")
        done
        if [[ "${#MONITOR_LIST[@]}" -eq 0 ]]; then
          warn "Nothing selected — defaulting to first monitor"
          MONITOR_LIST=("${DETECTED_MONITORS[0]}")
        fi
        ;;
    esac
  fi

else
  # ── Manual / no-X mode ────────────────────────────────
  printf "  %s(No X display detected — using preset layouts with placeholder names)%s\n\n" "$c_yel" "$c_rst"
  printf "  %sYou can edit ~/.config/dwm/monitors.sh after first login to use real names.%s\n\n" "$c_dim" "$c_rst"

  ask_choice "How many monitors do you have?" \
    "1  — single monitor" \
    "2  — dual monitor (horizontal)" \
    "2  — dual monitor (vertical)" \
    "3  — triple monitor (horizontal)"

  case "$LAST_CHOICE" in
    1) MONITOR_LIST=("HDMI-1") ;;
    2) MONITOR_LIST=("HDMI-1" "DP-1"); MONITOR_ARRANGEMENT="right-of" ;;
    3) MONITOR_LIST=("HDMI-1" "DP-1"); MONITOR_ARRANGEMENT="below" ;;
    4) MONITOR_LIST=("HDMI-1" "DP-1" "DP-2"); MONITOR_ARRANGEMENT="right-of" ;;
  esac
fi

ok "Monitors selected: ${MONITOR_LIST[*]}"

# ── Primary monitor ───────────────────────────────────────
printf "\n"
if [[ "${#MONITOR_LIST[@]}" -gt 1 ]]; then
  ask_choice "Which monitor is PRIMARY (where the bar appears)?" "${MONITOR_LIST[@]}"
  MONITOR_PRIMARY="${MONITOR_LIST[$((LAST_CHOICE-1))]}"
else
  MONITOR_PRIMARY="${MONITOR_LIST[0]}"
  printf "  %s(Single monitor — %s is primary)%s\n" "$c_dim" "$MONITOR_PRIMARY" "$c_rst"
fi
ok "Primary: $MONITOR_PRIMARY"

# ── Arrangement (only for 2+ monitors) ───────────────────
if [[ "${#MONITOR_LIST[@]}" -gt 1 ]]; then
  printf "\n"
  # Build human-readable non-primary list
  others=""
  for m in "${MONITOR_LIST[@]}"; do
    [[ "$m" != "$MONITOR_PRIMARY" ]] && others+="$m "
  done
  others="${others% }"

  ask_choice "How should [${others}] be positioned relative to [${MONITOR_PRIMARY}]?" \
    "RIGHT of $MONITOR_PRIMARY  (most common — side by side)" \
    "LEFT of $MONITOR_PRIMARY" \
    "ABOVE $MONITOR_PRIMARY" \
    "BELOW $MONITOR_PRIMARY" \
    "MIRROR $MONITOR_PRIMARY  (clone / same-as)"

  case "$LAST_CHOICE" in
    1) MONITOR_ARRANGEMENT="right-of" ;;
    2) MONITOR_ARRANGEMENT="left-of" ;;
    3) MONITOR_ARRANGEMENT="above" ;;
    4) MONITOR_ARRANGEMENT="below" ;;
    5) MONITOR_ARRANGEMENT="same-as" ;;
  esac
  ok "Arrangement: ${others} ${MONITOR_ARRANGEMENT} ${MONITOR_PRIMARY}"
fi

# ── Resolution per monitor ────────────────────────────────
printf "\n"
printf "%sResolution for each monitor:%s\n\n" "$c_bold" "$c_rst"

for mon in "${MONITOR_LIST[@]}"; do
  if [[ "$HAS_X" == "true" ]]; then
    # Collect up to 8 available modes
    mapfile -t avail_modes < <(xrandr --query | awk \
      -v m="$mon" 'BEGIN{f=0} /^'"$mon"' /{f=1;next} f&&/^\s+/{n++; if(n<=8) print $1} f&&!/^\s+/{exit}')
  else
    avail_modes=()
  fi

  printf "  %s[%s]%s\n" "$c_cyan" "$mon" "$c_rst"

  if [[ "${#avail_modes[@]}" -gt 0 ]]; then
    mode_opts=("Auto — let xrandr choose native resolution")
    for m in "${avail_modes[@]}"; do mode_opts+=("$m"); done
    mode_opts+=("Enter manually (e.g. 1920x1080)")

    ask_choice "  Resolution for $mon?" "${mode_opts[@]}"
    sel=$LAST_CHOICE

    if [[ "$sel" -eq 1 ]]; then
      MONITOR_MODES+=("auto"); MONITOR_RATES+=("0")
    elif [[ "$sel" -le $(( ${#avail_modes[@]} + 1 )) ]]; then
      chosen_mode="${avail_modes[$((sel-2))]}"
      # Try to get the refresh rate for this mode
      default_rate=$(xrandr --query | awk \
        -v m="$mon" -v mode="$chosen_mode" \
        'BEGIN{f=0} /^'"$mon"' /{f=1;next} f&&$1==mode{match($0,/[0-9]+\.[0-9]+\*/,a); if(a[0]) print int(a[0]); else print 0; exit} f&&!/^\s+/{exit}')
      MONITOR_MODES+=("$chosen_mode")
      MONITOR_RATES+=("${default_rate:-0}")
    else
      printf "    Enter resolution (e.g. 1920x1080): "
      read -r custom_res
      printf "    Enter refresh rate (e.g. 60 or 144), or 0 for auto: "
      read -r custom_rate
      MONITOR_MODES+=("$custom_res")
      MONITOR_RATES+=("${custom_rate:-0}")
    fi
  else
    # No X or no modes detected
    ask_choice "  Resolution for $mon?" \
      "Auto — let xrandr pick best" \
      "Enter manually"

    if [[ "$LAST_CHOICE" -eq 1 ]]; then
      MONITOR_MODES+=("auto"); MONITOR_RATES+=("0")
    else
      printf "    Enter resolution (e.g. 1920x1080): "
      read -r custom_res
      printf "    Refresh rate (e.g. 60 or 144), or 0 for auto: "
      read -r custom_rate
      MONITOR_MODES+=("$custom_res")
      MONITOR_RATES+=("${custom_rate:-0}")
    fi
  fi
done

# Build monitor summary string for display
MONITOR_SUMMARY="$MONITOR_PRIMARY (primary)"
if [[ "${#MONITOR_LIST[@]}" -gt 1 ]]; then
  for m in "${MONITOR_LIST[@]}"; do
    [[ "$m" == "$MONITOR_PRIMARY" ]] && continue
    MONITOR_SUMMARY+=", $m ($MONITOR_ARRANGEMENT)"
  done
fi
ok "Monitor setup: $MONITOR_SUMMARY"

# ─────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────
clear
printf "%s" "$c_bold$c_cyan"
cat << 'SUM_HDR'
  ╔════════════════════════════════════════════════════════╗
  ║                  Your DWM Configuration               ║
  ╚════════════════════════════════════════════════════════╝
SUM_HDR
printf "%s\n" "$c_rst"

printf "  %sColor scheme%s   %s\n"  "$c_bold" "$c_rst" "$SCHEME_NAME"
printf "  %sStatus bar%s     %s\n"  "$c_bold" "$c_rst" "$BAR_NAME"
printf "  %sTerminal%s       %s\n"  "$c_bold" "$c_rst" "$TERM_CMD"
printf "  %sLauncher%s       %s\n"  "$c_bold" "$c_rst" "$LAUNCHER_PKG"
printf "  %sCompositor%s     %s\n"  "$c_bold" "$c_rst" "$( [[ $USE_PICOM == y ]] && echo "picom (style $PICOM_STYLE)" || echo "none")"
printf "  %sFont%s           %s\n"  "$c_bold" "$c_rst" "$DWM_FONT"
printf "  %sWorkspaces%s     %s\n"  "$c_bold" "$c_rst" "$NUM_TAGS"
printf "  %sMonitors%s       %s\n" "$c_bold" "$c_rst" "$MONITOR_SUMMARY"
# Per-monitor resolutions
for idx in "${!MONITOR_LIST[@]}"; do
  mon="${MONITOR_LIST[$idx]}"
  mode="${MONITOR_MODES[$idx]:-auto}"
  rate="${MONITOR_RATES[$idx]:-0}"
  res_str="$mode"
  [[ "$rate" != "0" ]] && res_str+="@${rate}Hz"
  printf "    %s→%s %s: %s\n" "$c_dim" "$c_rst" "$mon" "$res_str"
done
printf "\n"
printf "  %sPatches:%s\n" "$c_bold" "$c_rst"
[[ "$USE_GAPS" == "1" ]]       && printf "    %s✓%s Gaps (%spx)\n"      "$c_grn" "$c_rst" "$GAP_SIZE"
[[ "$USE_SYSTRAY" == "1" ]]    && printf "    %s✓%s Systray\n"          "$c_grn" "$c_rst"
[[ "$USE_PERTAG" == "1" ]]     && printf "    %s✓%s Pertag\n"           "$c_grn" "$c_rst"
[[ "$USE_FULLSCREEN" == "1" ]] && printf "    %s✓%s Fullscreen\n"       "$c_grn" "$c_rst"
[[ "$USE_AUTOSTART" == "1" ]]  && printf "    %s✓%s Autostart\n"        "$c_grn" "$c_rst"
[[ "$USE_NOBORDER" == "1" ]]   && printf "    %s✓%s No-border\n"        "$c_grn" "$c_rst"
[[ "$USE_CMASTER" == "1" ]]    && printf "    %s✓%s CenteredMaster\n"   "$c_grn" "$c_rst"
printf "\n"

ask_yesno "Everything looks good? Start building DWM now?"
if [[ "$LAST_YESNO" == "n" ]]; then
  info "Aborted. Re-run to go through the wizard again."
  exit 0
fi

# ═════════════════════════════════════════════════════════
#  BUILD PHASE
# ═════════════════════════════════════════════════════════
detect_pm

BUILDS="$HOME/.local/src"
mkdir -p "$BUILDS"

# ── 1. build deps ─────────────────────────────────────────
install_build_deps

# ── 2. terminal ───────────────────────────────────────────
if [[ "$TERM_PKG" == "_build_st" ]]; then
  info "Building st (suckless terminal) from source…"
  cd "$BUILDS"
  [[ -d st ]] && rm -rf st
  git clone https://git.suckless.org/st st >/dev/null 2>&1
  cd st
  sudo make clean install >/dev/null 2>&1
  ok "st compiled and installed"
  cd "$BUILDS"
else
  install_pkg "$TERM_PKG"
fi

# ── 3. launcher ───────────────────────────────────────────
install_pkg "$LAUNCHER_PKG"

# ── 4. picom ──────────────────────────────────────────────
[[ "$USE_PICOM" == "y" ]] && install_pkg picom

# ── 5. font packages ──────────────────────────────────────
case "$FONT_CHOICE" in
  1) case "$PM" in
       pacman) pm_install ttf-jetbrains-mono-nerd ;;
       apt)    pm_install fonts-jetbrains-mono ;;
       dnf)    pm_install jetbrains-mono-fonts ;;
       *) warn "Install JetBrains Mono Nerd Font manually" ;;
     esac ;;
  2) case "$PM" in
       pacman) pm_install ttf-firacode-nerd ;;
       apt)    pm_install fonts-firacode ;;
       dnf)    pm_install fira-code-fonts ;;
       *) warn "Install FiraCode Nerd Font manually" ;;
     esac ;;
  3) case "$PM" in
       pacman) pm_install ttf-hack-nerd ;;
       apt)    pm_install fonts-hack-ttf ;;
       *) warn "Install Hack Nerd Font manually" ;;
     esac ;;
esac

# ── 6. clone dwm-flexipatch ───────────────────────────────
info "Cloning dwm-flexipatch…"
cd "$BUILDS"
if [[ -d dwm ]]; then
  warn "$BUILDS/dwm already exists — backing up to dwm.bak"
  rm -rf dwm.bak 2>/dev/null || true
  mv dwm dwm.bak
fi
if ! git clone https://github.com/bakkeby/dwm-flexipatch.git dwm 2>&1; then
  err "git clone failed — check your internet connection."
  exit 1
fi
ok "Cloned to $BUILDS/dwm"
cd "$BUILDS/dwm"

# ── 7. patches.h ──────────────────────────────────────────
info "Configuring patches.h…"

# dwm-flexipatch keeps patches.h in root; find it in case layout changed
PATCHES_H=""
for candidate in patches.h patch/patches.h patches/patches.h; do
  [[ -f "$candidate" ]] && { PATCHES_H="$candidate"; break; }
done
if [[ -z "$PATCHES_H" ]]; then
  err "patches.h not found. Files in repo root:"
  ls -1
  err "Try: cd $BUILDS/dwm && find . -name patches.h"
  exit 1
fi
info "Found patches.h at: $PATCHES_H"

enable_patch() {
  local p="$1"
  if grep -qE "^#define ${p}" "$PATCHES_H"; then
    sed -i "s/^#define ${p}.*/#define ${p} 1/" "$PATCHES_H"
    ok "  Enabled: $p"
  else
    warn "  Patch '$p' not found in patches.h (may have a different name this version)"
  fi
}

[[ "$USE_GAPS" == "1" ]]       && enable_patch "VANITYGAPS_PATCH"
[[ "$USE_SYSTRAY" == "1" ]]    && enable_patch "SYSTRAY_PATCH"
[[ "$USE_PERTAG" == "1" ]]     && enable_patch "PERTAG_PATCH"
[[ "$USE_FULLSCREEN" == "1" ]] && enable_patch "ACTUALFULLSCREEN_PATCH"
[[ "$USE_AUTOSTART" == "1" ]]  && enable_patch "AUTOSTART_PATCH"
[[ "$USE_NOBORDER" == "1" ]]   && enable_patch "NOBORDER_PATCH"
[[ "$USE_CMASTER" == "1" ]]    && enable_patch "CENTEREDMASTER_PATCH"

ok "patches.h done"

# ── 8. config.h ───────────────────────────────────────────
info "Generating config.h…"

# Build layouts block
LAYOUTS='static const Layout layouts[] = {\n\t/* symbol     arrange */\n\t{ "[]=",      tile    },\n\t{ "[M]",      monocle },'
[[ "$USE_CMASTER" == "1" ]] && LAYOUTS+=$'\n\t{ "|M|",      centeredmaster },'
LAYOUTS+=$'\n\t{ NULL,       NULL    },\n};'

# Build tags array string
TAGS_STR='{ '
for i in $(seq 1 "$NUM_TAGS"); do
  TAGS_STR+="\"$i\""
  (( i < NUM_TAGS )) && TAGS_STR+=", "
done
TAGS_STR+=' }'

# Build TAGKEYS lines
TAGKEYS_LINES=""
for i in $(seq 1 "$NUM_TAGS"); do
  TAGKEYS_LINES+="	TAGKEYS(                        XK_${i},                      $((i-1)))\n"
done

# Part 1: appearance + colors (needs variable expansion — unquoted heredoc)
cat > config.h << CONFIG_A
/* dwm config — generated by install-dwm.sh */
/* ${SCHEME_NAME} */

/* appearance */
static const unsigned int borderpx  = 2;
static const unsigned int snap      = 32;
static const int showbar            = 1;
static const int topbar             = 1;
static const char *fonts[]          = { "${DWM_FONT}" };
static const char dmenufont[]       = "${DWM_FONT}";

/* ${SCHEME_NAME} colors */
static const char col_bg[]     = "${COL_BG}";
static const char col_fg[]     = "${COL_FG}";
static const char col_bgsec[]  = "${COL_BGSEC}";
static const char col_accent[] = "${COL_ACCENT}";
static const char col_green[]  = "${COL_GREEN}";
static const char col_red[]    = "${COL_RED}";
static const char col_yellow[] = "${COL_YELLOW}";

static const char *colors[][3] = {
	/*                   fg           bg           border     */
	[SchemeNorm]     = { col_fg,      col_bg,      col_bgsec  },
	[SchemeSel]      = { col_bg,      col_accent,  col_accent },
};
CONFIG_A

# Part 2: gaps block (conditional — unquoted)
if [[ "$USE_GAPS" == "1" ]]; then
  cat >> config.h << CONFIG_GAPS

/* gaps (vanitygaps patch) */
static const unsigned int gappih    = ${GAP_SIZE};
static const unsigned int gappiv    = ${GAP_SIZE};
static const unsigned int gappoh    = ${GAP_SIZE};
static const unsigned int gappov    = ${GAP_SIZE};
static const int smartgaps          = 1;
CONFIG_GAPS
fi

# Part 3: tags, rules, layouts, key defs (literal C — quoted heredoc)
cat >> config.h << 'CONFIG_B'

/* tags / workspaces */
CONFIG_B

printf 'static const char *tags[] = %s;\n\n' "$TAGS_STR" >> config.h

cat >> config.h << 'CONFIG_C'
static const Rule rules[] = {
	/* class     instance  title  tags mask  isfloating  monitor */
	{ NULL,      NULL,     NULL,  0,         0,          -1      },
};

CONFIG_C

# layouts block (already has embedded newlines via \n)
printf "%b\n\n" "$LAYOUTS" >> config.h

# Part 4: key definitions (literal — quoted)
cat >> config.h << 'CONFIG_D'
/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY, view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY, toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY, tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY, toggletag,      {.ui = 1 << TAG} },

CONFIG_D

# Part 5: commands (needs variable expansion)
cat >> config.h << CONFIG_E
/* commands */
static const char *termcmd[]   = { "${TERM_CMD}", NULL };
static const char *launchcmd[] = { ${LAUNCH_ARRAY} };

CONFIG_E

# Part 6: keys array start (literal)
cat >> config.h << 'CONFIG_F'
static const Key keys[] = {
	/* modifier               key            function        argument */
	{ MODKEY|ShiftMask,       XK_Return,     spawn,          {.v = termcmd}       },
	{ MODKEY,                 XK_p,          spawn,          {.v = launchcmd}     },
	{ MODKEY,                 XK_b,          togglebar,      {0}                  },
	{ MODKEY,                 XK_j,          focusstack,     {.i = +1}            },
	{ MODKEY,                 XK_k,          focusstack,     {.i = -1}            },
	{ MODKEY,                 XK_i,          incnmaster,     {.i = +1}            },
	{ MODKEY,                 XK_d,          incnmaster,     {.i = -1}            },
	{ MODKEY,                 XK_h,          setmfact,       {.f = -0.05}         },
	{ MODKEY,                 XK_l,          setmfact,       {.f = +0.05}         },
	{ MODKEY,                 XK_Return,     zoom,           {0}                  },
	{ MODKEY,                 XK_Tab,        view,           {0}                  },
	{ MODKEY|ShiftMask,       XK_c,          killclient,     {0}                  },
	{ MODKEY,                 XK_t,          setlayout,      {.v = &layouts[0]}   },
	{ MODKEY,                 XK_m,          setlayout,      {.v = &layouts[1]}   },
	{ MODKEY,                 XK_space,      setlayout,      {0}                  },
	{ MODKEY|ShiftMask,       XK_space,      togglefloating, {0}                  },
	{ MODKEY,                 XK_0,          view,           {.ui = ~0}           },
	{ MODKEY|ShiftMask,       XK_0,          tag,            {.ui = ~0}           },
	{ MODKEY,                 XK_comma,      focusmon,       {.i = -1}            },
	{ MODKEY,                 XK_period,     focusmon,       {.i = +1}            },
	{ MODKEY|ShiftMask,       XK_comma,      tagmon,         {.i = -1}            },
	{ MODKEY|ShiftMask,       XK_period,     tagmon,         {.i = +1}            },
CONFIG_F

# Part 7: TAGKEYS lines (dynamically generated)
printf "%b" "$TAGKEYS_LINES" >> config.h

# Part 8: closing the keys array (literal)
cat >> config.h << 'CONFIG_G'
	{ MODKEY|ShiftMask,       XK_q,          quit,           {0}                  },
};

/* button bindings */
static const Button buttons[] = {
	{ ClkTagBar,     0,      Button1, view,           {0} },
	{ ClkTagBar,     0,      Button3, toggleview,     {0} },
	{ ClkTagBar,     MODKEY, Button1, tag,            {0} },
	{ ClkTagBar,     MODKEY, Button3, toggletag,      {0} },
	{ ClkWinTitle,   0,      Button2, zoom,           {0} },
	{ ClkStatusText, 0,      Button2, spawn,          {.v = termcmd} },
	{ ClkClientWin,  MODKEY, Button1, movemouse,      {0} },
	{ ClkClientWin,  MODKEY, Button2, togglefloating, {0} },
	{ ClkClientWin,  MODKEY, Button3, resizemouse,    {0} },
};
CONFIG_G

ok "config.h generated"

# ── 9. compile dwm ────────────────────────────────────────
info "Compiling dwm (dwm-flexipatch)…"
if sudo make clean install 2>&1; then
  ok "dwm compiled and installed!"
else
  err "Compilation failed. See output above."
  err "Common fix: edit $BUILDS/dwm/config.h, then run: cd $BUILDS/dwm && sudo make install"
  exit 1
fi

# ── 10. status bar ────────────────────────────────────────
if [[ "$BAR_NAME" == "slstatus" ]]; then
  info "Building slstatus from source…"
  cd "$BUILDS"
  [[ -d slstatus ]] && rm -rf slstatus
  git clone https://git.suckless.org/slstatus slstatus >/dev/null 2>&1
  cd slstatus

  cat > config.h << SLCONF
/* slstatus config — generated by install-dwm.sh */
static const struct arg args[] = {
	/* function    format        argument */
	{ cpu_perc,   " 󰻠 %s%%  ",  NULL     },
	{ ram_perc,   " 󰑭 %s%%  ",  NULL     },
	{ datetime,   " 󰃭 %s   ",   "%H:%M"  },
};
SLCONF

  sudo make clean install >/dev/null 2>&1
  ok "slstatus compiled and installed"
  cd "$BUILDS"

elif [[ "$BAR_NAME" == "dwmblocks" ]]; then
  info "Building dwmblocks from source…"
  cd "$BUILDS"
  [[ -d dwmblocks ]] && rm -rf dwmblocks
  git clone https://github.com/torrinfail/dwmblocks dwmblocks >/dev/null 2>&1
  cd dwmblocks

  # Create status scripts dir
  STATUS_DIR="$HOME/.local/bin/dwmblocks"
  mkdir -p "$STATUS_DIR"

  cat > blocks.h << 'BLKCONF'
/* dwmblocks config */
static const Block blocks[] = {
	/* icon   command                                  interval  signal */
	{ " 󰻠",  "~/.local/bin/dwmblocks/cpu.sh",         2,        0 },
	{ " 󰑭",  "~/.local/bin/dwmblocks/mem.sh",         5,        0 },
	{ " 󰃭",  "date '+%H:%M'",                          60,       0 },
};
static const char delim[] = "  ";
static const unsigned int delimLen = 2;
BLKCONF

  # CPU block script
  cat > "$STATUS_DIR/cpu.sh" << 'CPU_SH'
#!/bin/sh
grep 'cpu ' /proc/stat | awk '{
  idle=$5; total=$2+$3+$4+$5+$6+$7+$8
  if (NR==1) { i=idle; t=total }
  else printf "%d%%", (1-(idle-i)/(total-t))*100
}' - -
CPU_SH
  chmod +x "$STATUS_DIR/cpu.sh"

  # RAM block script
  cat > "$STATUS_DIR/mem.sh" << 'MEM_SH'
#!/bin/sh
free | awk '/^Mem:/ { printf "%d%%", $3/$2*100 }'
MEM_SH
  chmod +x "$STATUS_DIR/mem.sh"

  sudo make clean install >/dev/null 2>&1
  ok "dwmblocks compiled and installed"
  ok "Block scripts at $STATUS_DIR/"
  cd "$BUILDS"
fi

# ── 11. picom config ──────────────────────────────────────
if [[ "$USE_PICOM" == "y" ]]; then
  info "Writing picom config…"
  mkdir -p "$HOME/.config/picom"

  if [[ "$PICOM_STYLE" == "1" ]]; then
    cat > "$HOME/.config/picom/picom.conf" << 'PICOM_MIN'
# picom — minimal (shadows + fade)
backend      = "glx";
vsync        = true;
shadow        = true;
shadow-radius = 10;
shadow-opacity = 0.35;
shadow-offset-x = -5;
shadow-offset-y = -5;
fading        = true;
fade-in-step  = 0.05;
fade-out-step = 0.05;
PICOM_MIN

  elif [[ "$PICOM_STYLE" == "2" ]]; then
    cat > "$HOME/.config/picom/picom.conf" << 'PICOM_BLUR'
# picom — frosted glass blur
backend      = "glx";
vsync        = true;
blur-method   = "dual_kawase";
blur-strength  = 8;
blur-background = true;
shadow        = true;
shadow-radius = 12;
shadow-opacity = 0.4;
fading        = true;
fade-in-step  = 0.03;
fade-out-step = 0.03;
PICOM_BLUR
  fi
  ok "picom configured"
fi

# ── 12. xinitrc ───────────────────────────────────────────
info "Writing ~/.xinitrc…"

{
  printf '#!/bin/sh\n'
  printf '# ~/.xinitrc — generated by install-dwm.sh\n'
  printf '# Start DWM with: startx\n\n'

  printf '# Monitor layout (edit ~/.config/dwm/monitors.sh to change)\n'
  printf '[ -x "$HOME/.config/dwm/monitors.sh" ] && "$HOME/.config/dwm/monitors.sh"\n\n'

  printf '# Wallpaper — feh picks a random image from ~/.wallpapers/\n'
  printf 'if [ -d "$HOME/.wallpapers" ] && command -v feh >/dev/null 2>&1; then\n'
  printf '    feh --randomize --bg-fill "$HOME/.wallpapers/"\n'
  printf 'else\n'
  printf '    xsetroot -solid "%s"\n' "$COL_BG"
  printf 'fi\n\n'

  case "$BAR_NAME" in
    slstatus)  printf 'slstatus &\n' ;;
    dwmblocks) printf 'dwmblocks &\n' ;;
    builtin)   printf '# Built-in bar: run a loop like:\n# while true; do xsetroot -name "$(date +%%H:%%M)"; sleep 30; done &\n' ;;
  esac

  [[ "$USE_PICOM" == "y" ]] && [[ "$PICOM_STYLE" != "3" ]] && printf 'picom --daemon &\n'

  printf '\nexec dwm\n'
} > "$HOME/.xinitrc"
chmod +x "$HOME/.xinitrc"
ok "~/.xinitrc written"

# ── 13. monitors.sh ───────────────────────────────────────
info "Writing ~/.config/dwm/monitors.sh…"
mkdir -p "$HOME/.config/dwm"
{
  printf '#!/bin/sh\n'
  printf '# Monitor layout — generated by install-dwm.sh\n'
  printf '# Edit this file to change your layout, then run: startx\n'
  printf '#\n'
  printf '# To find your monitor names: xrandr --query | grep connected\n\n'

  # Find primary monitor index
  prim_idx=0
  for i in "${!MONITOR_LIST[@]}"; do
    [[ "${MONITOR_LIST[$i]}" == "$MONITOR_PRIMARY" ]] && prim_idx="$i"
  done

  # Build full xrandr command
  printf 'xrandr'

  # Primary monitor first
  pmode="${MONITOR_MODES[$prim_idx]:-auto}"
  prate="${MONITOR_RATES[$prim_idx]:-0}"
  if [[ "$pmode" == "auto" ]]; then
    printf ' \\\n    --output %s --auto --primary' "$MONITOR_PRIMARY"
  else
    printf ' \\\n    --output %s --mode %s' "$MONITOR_PRIMARY" "$pmode"
    [[ "$prate" != "0" ]] && printf ' --rate %s' "$prate"
    printf ' --primary'
  fi

  # Secondary monitors
  prev_mon="$MONITOR_PRIMARY"
  for i in "${!MONITOR_LIST[@]}"; do
    mon="${MONITOR_LIST[$i]}"
    [[ "$mon" == "$MONITOR_PRIMARY" ]] && continue
    mode="${MONITOR_MODES[$i]:-auto}"
    rate="${MONITOR_RATES[$i]:-0}"

    if [[ "$mode" == "auto" ]]; then
      printf ' \\\n    --output %s --auto' "$mon"
    else
      printf ' \\\n    --output %s --mode %s' "$mon" "$mode"
      [[ "$rate" != "0" ]] && printf ' --rate %s' "$rate"
    fi
    printf ' --%s %s' "$MONITOR_ARRANGEMENT" "$prev_mon"
    prev_mon="$mon"
  done
  printf '\n'

  # Turn off detected-but-unused monitors
  if [[ "${#DETECTED_MONITORS[@]}" -gt 0 ]]; then
    printf '\n# Turn off unused outputs\n'
    for dmon in "${DETECTED_MONITORS[@]}"; do
      in_use=false
      for umon in "${MONITOR_LIST[@]}"; do
        [[ "$dmon" == "$umon" ]] && in_use=true && break
      done
      if [[ "$in_use" == "false" ]]; then
        printf 'xrandr --output %s --off\n' "$dmon"
      fi
    done
  fi
} > "$HOME/.config/dwm/monitors.sh"
chmod +x "$HOME/.config/dwm/monitors.sh"
ok "monitors.sh written to ~/.config/dwm/monitors.sh"

# ── 14. autostart script ──────────────────────────────────
if [[ "$USE_AUTOSTART" == "1" ]]; then
  AUTOSTART_DIR="$HOME/.local/share/dwm"
  mkdir -p "$AUTOSTART_DIR"

  {
    printf '#!/bin/sh\n'
    printf '# DWM autostart — runs once when dwm starts (autostart patch)\n'
    printf '# Add your programs here.\n\n'
    case "$BAR_NAME" in
      slstatus)  printf 'slstatus &\n' ;;
      dwmblocks) printf 'dwmblocks &\n' ;;
    esac
    [[ "$USE_PICOM" == "y" ]] && [[ "$PICOM_STYLE" != "3" ]] && printf 'picom --daemon &\n'
  } > "$AUTOSTART_DIR/autostart.sh"
  chmod +x "$AUTOSTART_DIR/autostart.sh"
  ok "Autostart: $AUTOSTART_DIR/autostart.sh"
fi

# ── 15. wallpapers ────────────────────────────────────────
info "Setting up wallpapers…"
WALL_DIR="$HOME/.wallpapers"
mkdir -p "$WALL_DIR"

# Copy bundled personal wallpaper from the script directory (if present)
SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
if [[ -d "$SCRIPT_DIR/wallpapers" ]]; then
  cp -n "$SCRIPT_DIR/wallpapers/"* "$WALL_DIR/" 2>/dev/null || true
  ok "Bundled wallpapers copied to ~/.wallpapers/"
fi

# Download Catppuccin wallpapers if the directory is still empty
if [[ -z "$(ls -A "$WALL_DIR" 2>/dev/null)" ]]; then
  info "Downloading Catppuccin wallpapers…"
  local_tmp="/tmp/catppuccin-walls-$$"
  if git clone --depth=1 --filter=blob:none --no-checkout \
       https://github.com/catppuccin/wallpapers.git "$local_tmp" 2>/dev/null; then
    git -C "$local_tmp" sparse-checkout set --cone misc landscapes minimalistic 2>/dev/null || true
    git -C "$local_tmp" checkout 2>/dev/null || true
    find "$local_tmp" \( -name '*.png' -o -name '*.jpg' \) -not -path '*/.git/*' \
      -exec cp {} "$WALL_DIR/" \; 2>/dev/null || true
    rm -rf "$local_tmp"
    ok "Catppuccin wallpapers downloaded to ~/.wallpapers/"
  else
    warn "Could not download wallpapers — place a PNG/JPG in ~/.wallpapers/ manually"
  fi
fi

if [[ -n "$(ls -A "$WALL_DIR" 2>/dev/null)" ]]; then
  ok "Wallpapers ready in ~/.wallpapers/ (feh will pick one randomly on login)"
fi

# ═════════════════════════════════════════════════════════
#  DONE
# ═════════════════════════════════════════════════════════
clear
printf "%s" "$c_bold$c_grn"
cat << 'DONE'
  ╔════════════════════════════════════════════════════════╗
  ║          ✅  DWM installed successfully!              ║
  ╚════════════════════════════════════════════════════════╝
DONE
printf "%s\n" "$c_rst"

printf "  %sSource & config%s\n" "$c_bold" "$c_rst"
printf "    DWM:       %s/dwm/\n"       "$BUILDS"
printf "    config.h:  %s/dwm/config.h\n" "$BUILDS"
printf "    xinitrc:   ~/.xinitrc\n"
printf "    monitors:  ~/.config/dwm/monitors.sh\n"
[[ "$USE_AUTOSTART" == "1" ]] && printf "    autostart: ~/.local/share/dwm/autostart.sh\n"
[[ "$USE_PICOM" == "y" ]]     && printf "    picom:     ~/.config/picom/picom.conf\n"
printf "\n"

printf "  %sStarting DWM%s\n" "$c_bold" "$c_rst"
printf "    From TTY:        startx\n"
printf "    Display manager: add 'dwm' as a session\n"
printf "\n"

printf "  %sKey Bindings%s\n" "$c_bold" "$c_rst"
printf "    Super+Shift+Enter   Open terminal (%s)\n" "$TERM_CMD"
printf "    Super+P             Launch app (%s)\n"    "$LAUNCHER_PKG"
printf "    Super+1..%d         Switch workspace\n"  "$NUM_TAGS"
printf "    Super+J/K           Focus next/prev window\n"
printf "    Super+H/L           Resize master pane\n"
printf "    Super+Shift+C       Close window\n"
printf "    Super+Shift+Q       Quit DWM\n"
printf "\n"

printf "  %sMulti-monitor keys%s\n" "$c_bold" "$c_rst"
if [[ "${#MONITOR_LIST[@]}" -gt 1 ]]; then
  printf "    Super+,         Focus previous monitor\n"
  printf "    Super+.         Focus next monitor\n"
  printf "    Super+Shift+,   Move window to previous monitor\n"
  printf "    Super+Shift+.   Move window to next monitor\n"
  printf "\n"
fi

printf "  %sTo recustomize%s\n" "$c_bold" "$c_rst"
printf "    DWM config:    edit %s/dwm/config.h then sudo make install\n" "$BUILDS"
printf "    Monitors:      edit ~/.config/dwm/monitors.sh then startx\n"
printf "    Re-run wizard: bash install-dwm.sh\n"
printf "\n"
