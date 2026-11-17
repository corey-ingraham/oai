# oai — OpenAirInterface 5G on Ubuntu, with a taskbar launcher

Builds [OpenAirInterface](https://gitlab.eurecom.fr/oai/openairinterface5g) 5G NR (gNB `nr-softmodem` and UE
`nr-uesoftmodem`) for a **USRP B210** and the **RF simulator**, prepares Docker for the **OAI 5G core**, and adds an
"OpenAirInterface 5G" launcher to the menu and LXQt taskbar.

Target: **Ubuntu 26.04** desktop (22.04/24.04 also accepted), amd64, with `sudo` rights and internet access.

## Quick start

On a fresh machine, one line (clones this repo to `~/src/oai-installer`, then runs the installer):

```bash
curl -fsSL https://raw.githubusercontent.com/corey-ingraham/oai/main/bootstrap.sh | bash
```

Or from a clone:

```bash
git clone https://github.com/corey-ingraham/oai.git && cd oai
./install.sh            # lists every change, asks once, then runs (~30 min, mostly the build)
./install.sh --check    # verify; changes nothing
```

Log out and back in afterwards so `docker` works without sudo (the launcher falls back to sudo until then).

## First 5G session (no radio needed)

Click the taskbar icon (or run `oai-launch`):

- **1 Start 5G core** — pulls and starts the OAI CN5G containers (first run downloads ~1–2 GB). Wait for `s` to show them healthy.
- **3 Start gNB (rfsim)** — or **4** for the same with the imscope live constellation/scope window.
- **6 Start nrUE (rfsim)** — registers subscriber `001010000000001` and opens a PDU session (`oaitun_ue1`).
- **8 End-to-end test** — ping and iperf3 to the core's data network (192.168.70.135) through the UE tunnel.
- **9 Wireshark on core bridge** — NGAP, NAS, GTP-U and SBI traffic on interface `oai-cn5g`.

Each softmodem opens in its own window (asks for sudo) and logs to `~/.local/state/oai/`.

## Over the air with the B210

Plug the B210 into a USB 3 port, use **t** (CPU tuning, until reboot), then **Start gNB (USRP B210)**.
Band n78 needs a licence: use cables + attenuators, a shielded box, or an experimental licence. A phone needs a
programmable SIM (e.g. sysmoISIM) provisioned to match the core's database — see `docs/roadmap.md`.
Watch the carrier with any spectrum analyser or a second SDR.

## Other 5G tools

| Tool | Status | Why |
|---|---|---|
| Wireshark | optional: `sudo apt install wireshark` (menu item 9 needs it) | NGAP/NAS/F1AP/NR-RRC dissectors |
| SDRangel, GNU Radio, a spectrum analyser | optional | see your gNB's spectrum |
| iperf3 | installed by `install.sh`, own taskbar icon (`oai-iperf`) | throughput: UE tunnel DL/UL, any host, local server |
| pySim, UERANSIM, Open5GS, srsRAN Project, FlexRIC, 5GSniffer/NR-Scope, QCSuper/SCAT | roadmap | source builds — see `docs/roadmap.md` |

## Remove

`./uninstall.sh` removes the launcher, taskbar pin and core containers; the OAI source/build in
`~/src/openairinterface5g` and Ubuntu packages are kept.

## Licence

The scripts in this repo are [MIT](LICENSE). OpenAirInterface itself, which the installer downloads and
builds, is under its own licence (CSSL v1.0 since 2026.w14) and is not redistributed here.
