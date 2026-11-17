#!/usr/bin/env bash
# install.sh - build OpenAirInterface 5G (gNB + nrUE) for the USRP B210 and the RF simulator,
# set up the OAI 5G core's container runtime, and add a taskbar launcher.
#
# Shows every change it will make (with the exact command) and asks before running anything.
# Safe to re-run: steps that are already done are skipped.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$HERE/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Builds OAI (nr-softmodem + nr-uesoftmodem, USRP + RF simulator) from the tag pinned in
versions.tsv into ~/src/openairinterface5g, installs Docker for the OAI 5G core, and adds the
"OpenAirInterface 5G" launcher to the menu and the LXQt taskbar.

  --no-pin            don't pin the launcher on the taskbar
  --rebuild           rebuild OAI even if the binaries are current
  --print-commands    print the commands that would run, then exit (do it yourself)
  -y, --yes           don't ask; accept the listed changes
  --check             verify an existing install; changes nothing
  -h, --help          this help

OAI_SRC=/path overrides the source location. The system UHD is used as-is: OAI's own UHD
installer (build_oai -I -w USRP) removes all uhd packages first, so it is never called.
EOF
}

PIN=1; REBUILD=0; PRINT=0; YES=0; CHECK=0
while [ $# -gt 0 ]; do
    case "$1" in
        --no-pin)          PIN=0; shift ;;
        --rebuild)         REBUILD=1; shift ;;
        --print-commands)  PRINT=1; shift ;;
        -y|--yes)          YES=1; shift ;;
        --check)           CHECK=1; shift ;;
        -h|--help)         usage; exit 0 ;;
        *)                 die "unknown option: $1 (see --help)" ;;
    esac
done

detect_os
select_version
if [ "$CHECK" = 1 ]; then run_check; exit $?; fi
say "${C_B}OAI installer${C_0} - $OS_NAME, OpenAirInterface $TAG -> $OAI_SRC"

# --- 1. Ubuntu packages --------------------------------------------------------
read -r -a missing <<<"$(missing_pkgs)"
if [ "${#missing[@]}" -eq 0 ]; then ok "Ubuntu packages already installed"
else add_root_step "Install Ubuntu packages: ${missing[*]}" apt-get install -y "${missing[@]}"; fi

# --- 2. Docker access for the 5G core -------------------------------------------
if in_group docker; then ok "$ME is in the docker group"
else add_root_step "Let $ME run docker without sudo (takes effect at next login)" usermod -aG docker "$ME"; fi

# --- 3. B210 FPGA image ---------------------------------------------------------
if b210_image_ok; then ok "B210 FPGA image present"
else add_root_step "Download the UHD images for B2xx radios" uhd_images_downloader -t b2xx; fi

# --- 4. OAI source at the pinned tag ----------------------------------------------
cur="$(src_commit)"
if [ -z "$cur" ]; then
    [ -e "$OAI_SRC" ] && die "$OAI_SRC exists but is not a git checkout - move it aside"
    add_raw_step "Clone OAI $TAG (~120 MB) into $OAI_SRC" \
        "mkdir -p $(printf %q "$(dirname "$OAI_SRC")") && git -c advice.detachedHead=false clone --depth 1 --branch $(printf %q "$TAG") $(printf %q "$URL") $(printf %q "$OAI_SRC") && test \"\$(git -C $(printf %q "$OAI_SRC") rev-parse HEAD)\" = $COMMIT"
    cur="$COMMIT"
elif [ "$cur" = "$COMMIT" ]; then ok "OAI source at $TAG"
else warn "OAI source at ${cur:0:12}, not $TAG - building what is there (your changes are left alone)"; fi

# --- 5. OAI build dependencies (asn1c, SIMDE) --------------------------------------
# build_oai -I WITHOUT -w: installs the generic deps + asn1c (/opt/asn1c) + SIMDE and skips
# the per-radio block, which would apt-get remove the system UHD.
if have_deps; then ok "asn1c + SIMDE present"
else add_raw_step "Install OAI build deps: asn1c -> /opt/asn1c, SIMDE -> /usr/include (build_oai -I, no -w; asks sudo)" \
        "cd $(printf %q "$OAI_SRC/cmake_targets") && ./build_oai -I"; fi

# --- 6. Build gNB + nrUE --------------------------------------------------------
if [ "$REBUILD" = 0 ] && binaries_ok && [ "$(built_commit)" = "$cur" ]; then ok "OAI already built from ${cur:0:12}"
else add_raw_step "Build nr-softmodem + nr-uesoftmodem for USRP/rfsim with $BUILD_LIBS (~10-30 min, as $ME)" \
        "cd $(printf %q "$OAI_SRC/cmake_targets") && ./build_oai -w USRP --ninja --gNB --nrUE --build-lib $(printf %q "$BUILD_LIBS") && git -C $(printf %q "$OAI_SRC") rev-parse HEAD > $(printf %q "$STAMP")"; fi

# --- 7. Launcher -----------------------------------------------------------------
if launchers_ok; then ok "launchers installed"
else
    for i in "${!L_SRC[@]}"; do
        if ! file_ok "$i"; then add_root_step "Install ${L_DST[$i]}" install -D -m "${L_MODE[$i]}" "${L_SRC[$i]}" "${L_DST[$i]}"; fi
    done
fi

# --- 8. Taskbar pins ---------------------------------------------------------------
if [ "$PIN" = 1 ] && [ -f "$PANEL_CONF" ]; then
    for d in "${DESKTOPS[@]}"; do
        if pinned "$d"; then ok "already pinned on the taskbar: $(basename "$d")"
        else add_step "Pin $(basename "$d") on the LXQt taskbar (backs up panel.conf, restarts the panel)" bash "$HERE/lib/panel-pin.sh" pin "$d"; fi
    done
fi

# --- Review, then run --------------------------------------------------------------
if [ "${#STEP_CMD[@]}" -eq 0 ]; then
    say "Nothing to change."
    run_check; exit $?
fi
say ""
say "${C_B}These changes will be made:${C_0}"
show_steps
say ""
if [ "$PRINT" = 1 ]; then
    say "(--print-commands: nothing was run. Run the commands above yourself, then ./install.sh --check)"
    exit 0
fi
if ! confirm "Make these changes?"; then
    say "Nothing changed. To do it yourself: ./install.sh --print-commands"
    exit 0
fi
run_steps
say ""
run_check || true
in_group docker && ! docker info >/dev/null 2>&1 && say "${C_WARN}Log out and back in so docker works without sudo (the launcher falls back to sudo until then).${C_0}"
exit 0
