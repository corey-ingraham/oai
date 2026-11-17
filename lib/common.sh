# lib/common.sh - shared helpers for install.sh and uninstall.sh. Sourced, not executed.
# shellcheck shell=bash
# Variables set here are used by the scripts that source this file.
# shellcheck disable=SC2034

if [ -t 1 ]; then C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_FAIL=$'\033[31m'; C_B=$'\033[1m'; C_0=$'\033[0m'
else C_OK=""; C_WARN=""; C_FAIL=""; C_B=""; C_0=""; fi
say()  { printf '%s\n' "$*"; }
ok()   { printf '  %sok%s    %s\n' "$C_OK" "$C_0" "$*"; }
warn() { printf '  %sWARN%s  %s\n' "$C_WARN" "$C_0" "$*"; }
fail() { printf '  %sFAIL%s  %s\n' "$C_FAIL" "$C_0" "$*"; }
info() { printf '  info  %s\n' "$*"; }
die()  { printf '%serror:%s %s\n' "$C_FAIL" "$C_0" "$*" >&2; exit 1; }

# Builds, the source tree and the taskbar belong to the desktop user, so never run as root;
# individual steps use sudo.
[ "$(id -u)" -ne 0 ] || die "run as your normal user, not root - steps that need root use sudo"
SUDO=sudo
ME="$(id -un)"

OAI_SRC="${OAI_SRC:-$HOME/src/openairinterface5g}"
OAI_BUILD="$OAI_SRC/cmake_targets/ran_build/build"
STAMP="$OAI_BUILD/.oai-installer-commit"           # commit the binaries were built from
BUILD_LIBS="nrscope imscope telnetsrv"

# Launchers: menu script + .desktop + icon each. Parallel arrays: source in the repo, destination, mode.
APPS=/usr/share/applications; ICONS=/usr/share/icons/hicolor/scalable/apps
L_SRC=("$HERE/launcher/oai-launch" "$HERE/launcher/oai.desktop" "$HERE/launcher/oai.svg"
       "$HERE/launcher/oai-iperf"  "$HERE/launcher/oai-iperf.desktop" "$HERE/launcher/oai-iperf.svg")
L_DST=(/usr/local/bin/oai-launch "$APPS/oai.desktop" "$ICONS/oai.svg"
       /usr/local/bin/oai-iperf  "$APPS/oai-iperf.desktop" "$ICONS/oai-iperf.svg")
L_MODE=(0755 0644 0644 0755 0644 0644)
DESKTOPS=("$APPS/oai.desktop" "$APPS/oai-iperf.desktop")    # pinned on the taskbar, in this order
PANEL_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/lxqt/panel.conf"

# Ubuntu packages: OAI build deps (from build_helper check_install_oai_software + asn1c),
# nrscope (libforms) and imscope (glfw/GL) deps, UHD from the distro, the core's container
# runtime, and the tools the launcher uses.
APT_PKGS=(automake build-essential cmake ninja-build pkg-config git libreadline-dev libconfig-dev
          libsctp-dev libssl-dev libtool patch openssl zlib1g-dev xxd libyaml-cpp-dev bison flex
          libforms-dev libforms-bin libglfw3-dev libgl-dev
          libuhd-dev uhd-host
          docker.io docker-compose-v2 iperf3 qterminal)

detect_os() {
    [ -r /etc/os-release ] || die "cannot read /etc/os-release"
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_NAME="${PRETTY_NAME:-unknown}"
    [ "${ID:-}" = ubuntu ] || [ -n "${UBUNTU_CODENAME:-}" ] || die "$OS_NAME is not Ubuntu"
    case "${VERSION_ID:-}" in
        22.04|24.04|26.04) ;;                    # build_helper check_supported_distribution
        *) die "Ubuntu ${VERSION_ID:-?} is not supported by OAI (22.04, 24.04, 26.04)" ;;
    esac
}

# select_version: first row of versions.tsv -> TAG, COMMIT, URL
select_version() {
    local row
    row="$(grep -v '^#' "$HERE/versions.tsv" | head -1)"
    [ -n "$row" ] || die "versions.tsv is empty"
    IFS=$'\t' read -r TAG COMMIT URL <<<"$row"
}

# "ok installed" with any want-state: some distros (e.g. DragonOS) put libuhd-dev on hold ("hold ok installed").
pkg_installed() { dpkg-query -W -f='${Status}\n' "$1" 2>/dev/null | grep -q ' ok installed$'; }
missing_pkgs()  { local p; for p in "${APT_PKGS[@]}"; do pkg_installed "$p" || printf '%s ' "$p"; done; return 0; }
src_commit()    { git -C "$OAI_SRC" rev-parse HEAD 2>/dev/null || true; }
built_commit()  { cat "$STAMP" 2>/dev/null || true; }
have_deps()     { [ -x /opt/asn1c/bin/asn1c ] && [ -d /usr/include/simde ]; }
binaries_ok()   { [ -x "$OAI_BUILD/nr-softmodem" ] && [ -x "$OAI_BUILD/nr-uesoftmodem" ]; }
in_group()      { id -nG "$ME" | tr ' ' '\n' | grep -qx "$1"; }
pinned()        { [ -f "$PANEL_CONF" ] && grep -qF "\\desktop=$1" "$PANEL_CONF"; }
file_ok()       { cmp -s "${L_SRC[$1]}" "${L_DST[$1]}"; }
launchers_ok()  { local i; for i in "${!L_SRC[@]}"; do file_ok "$i" || return 1; done; }
uhd_images_dir(){ uhd_config_info --images-dir 2>/dev/null | sed 's/.*: *//' || true; }
b210_image_ok() { local d; d="$(uhd_images_dir)"; [ -n "$d" ] && [ -f "$d/usrp_b210_fpga.bin" ]; }
b2xx_on_usb()   { lsusb -d 2500: >/dev/null 2>&1; }

# run_check: read-only verification. Returns non-zero if anything is wrong.
run_check() {
    local bad=0 m c b
    say "${C_B}check:${C_0}"
    m="$(missing_pkgs)"
    if [ -z "$m" ]; then ok "all ${#APT_PKGS[@]} Ubuntu packages installed"; else fail "missing packages: $m"; bad=1; fi
    if have_deps; then ok "asn1c (/opt/asn1c) and SIMDE (/usr/include/simde) present"; else fail "asn1c or SIMDE missing (OAI build deps)"; bad=1; fi
    c="$(src_commit)"
    if [ -z "$c" ]; then fail "no OAI source at $OAI_SRC"; bad=1
    elif [ "$c" = "$COMMIT" ]; then ok "source $OAI_SRC at pinned $TAG (${c:0:12})"
    else warn "source at ${c:0:12}, not the pinned $TAG (${COMMIT:0:12}) - your changes are left alone"; fi
    b="$(built_commit)"
    if ! binaries_ok; then fail "nr-softmodem / nr-uesoftmodem not built in $OAI_BUILD"; bad=1
    elif [ -n "$c" ] && [ "$b" != "$c" ]; then warn "binaries built from ${b:0:12}, source is ${c:0:12} - rebuild with ./install.sh"
    elif ldd "$OAI_BUILD/nr-softmodem" | grep -q 'not found'; then fail "nr-softmodem has missing libraries (ldd)"; bad=1
    else ok "nr-softmodem + nr-uesoftmodem built from ${b:0:12}, libraries resolve"; fi
    if systemctl is-active -q docker 2>/dev/null; then ok "docker daemon running"; else fail "docker daemon not running"; bad=1; fi
    if in_group docker; then
        if docker info >/dev/null 2>&1; then ok "$ME can use docker without sudo"
        else warn "$ME is in the docker group but this session predates it - log out and back in"; fi
    else fail "$ME is not in the docker group"; bad=1; fi
    info "UHD $(uhd_config_info --version 2>/dev/null | sed 's/^UHD //' | head -1) (system package; OAI's UHD reinstall is never run)"
    if b210_image_ok; then ok "B210 FPGA image present ($(uhd_images_dir))"; else fail "B210 FPGA image missing - ./install.sh downloads it"; bad=1; fi
    if b2xx_on_usb; then ok "USRP B2xx on USB: $(lsusb -d 2500: | head -1 | cut -d' ' -f7-)"
    else info "no USRP B2xx on USB right now (RF simulator works without one)"; fi
    in_group usrp || info "$ME is not in the usrp group (only needed for non-root UHD tools)"
    local i d
    if launchers_ok; then ok "launchers installed (oai-launch, oai-iperf: scripts, menu entries, icons)"
    else
        for i in "${!L_SRC[@]}"; do file_ok "$i" || fail "missing or out of date: ${L_DST[$i]}"; done; bad=1
    fi
    if [ -f "$PANEL_CONF" ]; then
        for d in "${DESKTOPS[@]}"; do
            if pinned "$d"; then ok "pinned on the LXQt taskbar: $(basename "$d")"
            else warn "not pinned on the taskbar: $(basename "$d") (./install.sh pins it; --no-pin skips)"; fi
        done
    fi
    if [ "$bad" = 0 ]; then say "${C_OK}All checks passed.${C_0}"; else say "${C_FAIL}Some checks failed (see above).${C_0}"; fi
    return "$bad"
}

# Planned-change list: every step is shown (description + exact command) before anything runs.
STEP_DESC=(); STEP_CMD=()
add_step()      { STEP_DESC+=("$1"); shift; STEP_CMD+=("$(printf '%q ' "$@")"); }
add_root_step() { local d="$1"; shift; add_step "$d" "$SUDO" "$@"; }
add_raw_step()  { STEP_DESC+=("$1"); STEP_CMD+=("$2"); }   # caller quotes; for pipelines

show_steps() {
    local i
    for i in "${!STEP_DESC[@]}"; do
        printf '  %d. %s\n       %s\n' "$((i + 1))" "${STEP_DESC[$i]}" "${STEP_CMD[$i]% }"
    done
}

confirm() {
    [ "${YES:-0}" = 1 ] && return 0
    [ -t 0 ] || die "no terminal to ask on - re-run with --yes to accept, or --print-commands to do it yourself"
    local a; read -r -p "$1 [Y/n] " a
    case "$a" in ""|y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

run_steps() {
    local i
    for i in "${!STEP_CMD[@]}"; do
        say "${C_B}[$((i + 1))/${#STEP_CMD[@]}]${C_0} ${STEP_DESC[$i]}"
        eval "${STEP_CMD[$i]}"
    done
}
