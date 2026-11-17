#!/usr/bin/env bash
# panel-pin.sh pin|unpin DESKTOP_FILE - add/remove a launcher on the LXQt panel's quick-launch bar.
# Runs as the desktop user (never root). Idempotent: pinning twice changes nothing.
# Backs up panel.conf first (panel.conf.bak-YYYYmmddHHMMSS), then restarts lxqt-panel with
# SIGKILL so the running panel cannot write its old settings back over the edit on exit.
set -euo pipefail
action="${1:?pin|unpin}"; desktop="${2:?desktop file path}"
conf="${XDG_CONFIG_HOME:-$HOME/.config}/lxqt/panel.conf"
[ -f "$conf" ] || { echo "no LXQt panel config at $conf - skipping taskbar pin"; exit 0; }
grep -q '^\[quicklaunch\]' "$conf" || { echo "panel has no quick-launch bar ([quicklaunch]) - add one in panel settings, then re-run"; exit 1; }

if [ "$action" = pin ] && grep -qF "\\desktop=$desktop" "$conf"; then echo "already pinned"; exit 0; fi
if [ "$action" = unpin ] && ! grep -qF "\\desktop=$desktop" "$conf"; then echo "not pinned"; exit 0; fi

cp -p "$conf" "$conf.bak-$(date +%Y%m%d%H%M%S)"
tmp="$(mktemp "$conf.XXXX")"
# Rewrite the [quicklaunch] section: collect its apps\N\desktop entries in order, add/remove ours,
# renumber 1..n and write apps\size=n. Everything outside the section is copied unchanged.
awk -v act="$action" -v want="$desktop" '
    function flush(   i) {
        if (act == "pin") apps[++n] = want
        for (i = 1; i <= n; i++) printf "apps\\%d\\desktop=%s\n", i, apps[i]
        printf "apps\\size=%d\n", n
        done = 1
    }
    /^\[/ { if (inq && !done) flush(); inq = ($0 == "[quicklaunch]"); print; next }
    inq && /^apps\\[0-9]+\\desktop=/ { v = $0; sub(/^apps\\[0-9]+\\desktop=/, "", v); if (v != want) apps[++n] = v; next }
    inq && /^apps\\size=/ { next }
    inq && /^[[:space:]]*$/ && !done { flush(); print; next }
    { print }
    END { if (inq && !done) flush() }
' "$conf" > "$tmp"
mv "$tmp" "$conf"
echo "${action}ned $desktop in $conf"

[ "${OAI_NO_PANEL_RESTART:-0}" = 1 ] && exit 0   # tests edit a copy; leave the live panel alone
if pgrep -x lxqt-panel >/dev/null; then
    pkill -KILL -x lxqt-panel
    for _ in 1 2 3 4 5 6; do sleep 0.5; pgrep -x lxqt-panel >/dev/null && break; done
    pgrep -x lxqt-panel >/dev/null || (setsid lxqt-panel >/dev/null 2>&1 &)
    echo "lxqt-panel restarted"
fi
