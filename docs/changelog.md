# Changelog

## 2026-11-16 — public release: bootstrap installer

- [bootstrap.sh](../bootstrap.sh): `curl … | bash` on a fresh Ubuntu 26.04 — installs git, clones to `~/src/oai-installer`, runs `install.sh` with prompts on the terminal.
- Docs made machine-neutral; Wireshark is optional (menu item 9 says how to install it).

## 2026-11-16 — iperf3 taskbar launcher [RM-001]

- [launcher/oai-iperf](../launcher/oai-iperf) + `.desktop` + icon: UE-tunnel DL/UL test to the core's ext-dn, client to any host (TCP/UDP, up/down/bidir), local server.
- [lib/common.sh](../lib/common.sh), [install.sh](../install.sh), [uninstall.sh](../uninstall.sh): launchers are now a list (`L_SRC`/`L_DST`/`DESKTOPS`).
- Install verified: `./install.sh --check` all ok after the first install run (docker group needs re-login).

## 2026-11-16 — repo created: installer, launcher, taskbar pin [RM-001]

- [install.sh](../install.sh), [lib/common.sh](../lib/common.sh): pinned OAI `2026.w46` build for USRP + rfsim, Docker for CN5G, guarded against OAI's UHD reinstall.
- [launcher/oai-launch](../launcher/oai-launch) + `.desktop` + icon; [lib/panel-pin.sh](../lib/panel-pin.sh) pin/unpin tested on a copy of `panel.conf` (pin, re-pin no-op, unpin byte-identical).
- [uninstall.sh](../uninstall.sh).
