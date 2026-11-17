# Config

| Item | Value |
|---|---|
| OAI RAN | `2026.w46` → `cb98db5b5d2d95c86673821bfc9fa1be9e225b97` (`versions.tsv`) |
| Source / build | `~/src/openairinterface5g` · `cmake_targets/ran_build/build/` (override with `OAI_SRC`) |
| Build stamp | `ran_build/build/.oai-installer-commit` |
| Core compose | `$OAI_SRC/doc/tutorial_resources/oai-cn5g/docker-compose.yaml` (OAI NFs v2.2.2; `ims`, `trf-gen-cn5g` float on `latest`) |
| gNB config | `targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf` (PLMN 001/01, n78, 106 PRB, AMF .132) |
| UE (rfsim) | `-r 106 --numerology 1 --band 78 -C 3619200000 --uicc0.imsi 001010000000001`; credentials = OAI tutorial test subscriber in the core's database SQL (public test values, location only) |
| UHD | Ubuntu's `libuhd-dev` / `uhd-host` (never replaced by OAI's UHD installer); images dir from `uhd_config_info --images-dir` |
| B210 USB | vendor `2500` (Ettus); user in `usrp` group |
| Logs | `~/.local/state/oai/{gnb-rfsim,gnb-b210,ue-rfsim}.log` |
| Panel | `~/.config/lxqt/panel.conf` `[quicklaunch]`; backups `panel.conf.bak-YYYYmmddHHMMSS` |

## Files installed

`/usr/local/bin/{oai-launch,oai-iperf}` · `/usr/share/applications/{oai,oai-iperf}.desktop` · `/usr/share/icons/hicolor/scalable/apps/{oai,oai-iperf}.svg` ·
`/opt/asn1c/` · `/usr/include/simde/` · apt packages listed in `lib/common.sh` `APT_PKGS`.
