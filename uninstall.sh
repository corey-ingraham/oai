#!/usr/bin/env bash
# uninstall.sh - remove the launcher and taskbar pin, and optionally stop/remove the 5G core.
# Leaves the OAI source/build (~/src/openairinterface5g), Ubuntu packages, asn1c/SIMDE and the
# docker group membership alone: other tools may use them. It lists what it would delete.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$HERE/lib/common.sh"

PRINT=0; YES=0
for a in "$@"; do case "$a" in
    --print-commands) PRINT=1 ;; -y|--yes) YES=1 ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;; *) die "unknown option: $a" ;; esac; done

CN5G="$OAI_SRC/doc/tutorial_resources/oai-cn5g/docker-compose.yaml"
if [ -f "$CN5G" ] && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx oai-amf; then
    add_step "Stop and remove the OAI 5G core containers" docker compose -f "$CN5G" down
fi
for d in "${DESKTOPS[@]}"; do
    if pinned "$d"; then add_step "Unpin $(basename "$d") from the LXQt taskbar (backs up panel.conf)" bash "$HERE/lib/panel-pin.sh" unpin "$d"; fi
done
for f in "${L_DST[@]}"; do
    if [ -e "$f" ]; then add_root_step "Remove $f" rm -f "$f"; fi
done

if [ "${#STEP_CMD[@]}" -eq 0 ]; then say "Nothing to remove."; exit 0; fi
say "${C_B}These changes will be made:${C_0}"; show_steps
if [ "$PRINT" = 1 ]; then exit 0; fi
confirm "Remove?" || { say "Nothing changed."; exit 0; }
run_steps
say "Kept: $OAI_SRC (delete it yourself if you want the ~2 GB back)."
