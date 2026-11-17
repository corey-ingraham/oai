# Architecture

## Layout

| Path | Role |
|---|---|
| `bootstrap.sh` | `curl … \| bash` entry: installs git, clones/updates the repo, runs `install.sh` on the terminal |
| `install.sh` | plan → confirm → run; `--check` read-only verifier |
| `uninstall.sh` | removes launcher, pin, core containers; keeps source/packages |
| `lib/common.sh` | paths, package list, checks, step/confirm helpers |
| `lib/panel-pin.sh` | idempotent LXQt quick-launch pin/unpin (renumbers `apps\N`, backs up, SIGKILL-restarts panel) |
| `launcher/oai-launch` | menu: core up/down, gNB rfsim/B210/imscope, nrUE rfsim, e2e test, Wireshark, tune, status |
| `launcher/oai.desktop`, `oai.svg` | menu entry + icon (`Exec=qterminal -e /usr/local/bin/oai-launch`) |
| `launcher/oai-iperf` (+ `.desktop`, `.svg`) | iperf3 menu: UE-tunnel DL/UL to ext-dn, client to any host, local server |
| `versions.tsv` | pinned OAI tag + peeled commit |

## Install flow

1. apt packages missing from `APT_PKGS` (packages on apt hold count as installed).
2. `usermod -aG docker` (next login).
3. `uhd_images_downloader -t b2xx` if the B210 FPGA image is absent.
4. Clone the pinned tag (shallow) into `~/src/openairinterface5g`; verify the peeled commit. An existing checkout at
   another commit is left alone (it may be your own work).
5. `build_oai -I` (no `-w`): generic deps + asn1c → `/opt/asn1c` + SIMDE → `/usr/include/simde`.
6. `build_oai -w USRP --ninja --gNB --nrUE --build-lib "nrscope imscope telnetsrv"`; stamp file records the commit.
7. Install launcher, icon, `.desktop` (root), then pin on the taskbar (user).

## What runs as root

apt, usermod, uhd_images_downloader, `install` into `/usr/local/bin` and `/usr/share`, the sudo calls inside
`build_oai -I`, and at run time the softmodems (real-time threads, tun device) and CPU tuning. The build itself and
the panel edit run as the user.

## Network (from the in-tree CN5G compose)

Bridge `oai-cn5g`, 192.168.70.128/26. gNB binds the bridge gateway .129 (NG/NGU); AMF .132, SMF .133, UPF .134,
ext-dn .135, NRF .130, MySQL .131. No ports are published to the host. RF simulator gNB ↔ UE over 127.0.0.1.
