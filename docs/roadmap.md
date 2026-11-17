# Roadmap

> `RM-NNN` shares one counter with `ISSUE-NNN`. Newest first.

## Resume here

RM-001: run the rfsim session from the taskbar icon (menu 1 → 3 → 6 → 8).


### RM-003 — extra 5G tools (source builds) · planned (2026-11-16)

None of these are packaged for Ubuntu 26.04; each becomes an opt-in `install.sh --with-<tool>` once wanted.
- **pySim** — program sysmoISIM/sysmoUSIM cards so a COTS phone attaches (needed for RM-002 with a phone).
- **UERANSIM** — software UE/gNB to exercise the core without OAI RAN.
- **Open5GS** — second core for interop testing.
- **srsRAN Project** — second gNB (B210 supported) for comparison.
- **FlexRIC** — O-RAN near-RT RIC / E2 agent for OAI (xApps).
- **5GSniffer / NR-Scope**, **QCSuper / SCAT** — passive NR DL sniffing on the B210; phone diag logs.
Design question: which first? (pySim if a phone is the UE.)

### RM-002 — over-the-air with the B210 · planned (2026-11-16)

Goal: gNB on B210 at n78 40 MHz (106 PRB) with a UE attached and iperf3 passing, no `L`/`U` storm in the log.
Prerequisites: B210 in hand; licence or cabled/attenuated/shielded setup; UE = phone + programmable SIM (RM-003 pySim)
or nrUE on a second SDR. Watch the carrier on a spectrum analyser. If late/underflow: tune (`t`), pin gNB to P-cores
(from `lscpu -e`), drop to 20 MHz, log an ISSUE.

### RM-001 — install OAI + launcher, rfsim end-to-end · in-progress (2026-11-16)

Done: repo, installer, launchers (OAI + iperf3), install run, `--check` all ok 2026-11-16. Verified after
re-login 2026-11-16: docker group active, `--check` all ok, re-run says "Nothing to change". Left: (b) UE gets
`oaitun_ue1` + ping + iperf3 to 192.168.70.135, (c) taskbar icon opens the menu.
