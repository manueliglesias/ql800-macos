# Brother QL-800 Print-from-Any-App Setup

## Overview

Enables printing to a Brother QL-800 with a DK-2251 62mm red/black continuous roll from any macOS app via the PDF menu. A PDF Services shell script captures print jobs, converts them to PNG via `sips`, and queues them for a LaunchAgent worker that runs outside the macOS PDF Services sandbox with full USB access.

## Prerequisites

- macOS
- Brother QL-800 connected via USB
- Homebrew installed at `/opt/homebrew`
- Python 3 available via `python3`
- `libusb` installed via Homebrew: `brew install libusb`

## Directory Structure

The project files live in this repository directory. Runtime files must not be loaded from this source tree; `make deploy` copies everything needed to installed locations.

```
ql800-macos/
├── AGENTS.md
├── Makefile
├── .gitignore
├── requirements.txt
├── print_label.py
├── worker.sh
├── Print to QL-800.sh
└── dev.iglesias.ql800.plist.template       # Makefile generates the real plist from this
```

System locations managed by `make deploy`:

```
~/Library/Application Support/dev.iglesias.ql800/
├── .venv/
├── print_label.py
├── requirements.txt
└── worker.sh

~/Library/PDF Services/
└── Print to QL-800.sh

~/Library/LaunchAgents/
└── dev.iglesias.ql800.plist

/tmp/ql800_pending/
└── job_*.png
```

## Source Map

Use the real files in this folder as the source of truth:

| File | Role |
|------|------|
| `Makefile` | Installs runtime files, creates the installed venv, deploys/undeploys the PDF Service and LaunchAgent, and checks that the installed venv has `brother_ql` |
| `requirements.txt` | Python dependencies installed into the runtime venv by `make venv` / `make deploy` |
| `print_label.py` | Sends PNG files to the Brother QL-800 via `brother_ql` and the `pyusb` backend |
| `Print to QL-800.sh` | PDF Services entry point; converts the incoming PDF to a queued PNG with `sips` |
| `worker.sh` | LaunchAgent worker; prints queued PNGs from `/tmp/ql800_pending` |
| `dev.iglesias.ql800.plist.template` | LaunchAgent plist template; `make deploy` substitutes the project path |

Avoid copying full file contents into this document. Keep implementation details in the source files to prevent drift.

## First-Time Setup

```bash
# 1. Install libusb
brew install libusb

# 2. Enter this project directory
cd /path/to/ql800-macos

# 3. Deploy
make deploy

# 4. Verify
launchctl list | grep ql800
# Expected: -    0    dev.iglesias.ql800
```

## Iterating

After editing project files:

```bash
make deploy
```

Use `make reload` when you specifically want an explicit undeploy and deploy cycle. Plist template changes require reloading the LaunchAgent.

## Usage

In any app: **File -> Print -> PDF -> Print to QL-800**

## Log Files

| File | Purpose |
|------|---------|
| `/tmp/ql800_debug.log` | PDF Services script output and `sips` conversion |
| `/tmp/ql800_worker.log` | Worker script output and `python` / `brother_ql` print status |

## Key Design Decisions

| Problem | Solution |
|---------|----------|
| Runtime should not depend on the source checkout | `make deploy` installs scripts and the venv under `~/Library/Application Support/dev.iglesias.ql800` |
| PDF Services sandbox blocks USB | LaunchAgent worker runs in the full user session |
| PDF Services sandbox blocks Homebrew binaries | Only use `sips` in the PDF Services script |
| PDF Services sandbox blocks `launchctl` | Use LaunchAgent `WatchPaths` on `/tmp/ql800_pending` |
| Launchd does not expand env vars in plists | Makefile substitutes `__INSTALL_DIR__` via `sed` |
| Repo may not live at `~/ql800` | Runtime paths point at the installed Application Support directory |
| Missing venv causes delayed runtime failure | `make deploy` creates and checks the installed venv before launching |
| `brother_ql` CUPS backend removed | Use the `pyusb` backend exclusively |
| PDF path is last arg, not `$1` | Use `${@: -1}` in the PDF Services script |
