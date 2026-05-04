# Brother QL-800 Print-from-Any-App Setup

## Overview

Enables printing to a Brother QL-800 with a DK-2251 62mm red/black continuous roll from any macOS app via the PDF menu. A PDF Services shell script captures print jobs and queues PDFs for a LaunchAgent worker that runs outside the macOS PDF Services sandbox with full USB access. The worker renders PDF pages and prints each page as its own label.

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
├── job_*.pdf
├── job_*.png                  # legacy/manual queued image jobs are still supported
└── failed/
    └── *.failed_*
```

## Source Map

Use the real files in this folder as the source of truth:

| File | Role |
|------|------|
| `Makefile` | Installs runtime files, creates the installed venv, deploys/undeploys the PDF Service and LaunchAgent, and checks that the installed venv has required Python dependencies |
| `requirements.txt` | Python dependencies installed into the runtime venv by `make venv` / `make deploy` |
| `print_label.py` | Renders queued PDFs to page images and sends each image to the Brother QL-800 via `brother_ql` and the `pyusb` backend |
| `Print to QL-800.sh` | PDF Services entry point; atomically queues the incoming PDF |
| `worker.sh` | LaunchAgent worker; prints queued PDF and PNG jobs from `/tmp/ql800_pending` |
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
| `/tmp/ql800_debug.log` | PDF Services script output and queued PDF path |
| `/tmp/ql800_worker.log` | Worker script output and `python` / `brother_ql` print status |

## Key Design Decisions

| Problem | Solution |
|---------|----------|
| Runtime should not depend on the source checkout | `make deploy` installs scripts and the venv under `~/Library/Application Support/dev.iglesias.ql800` |
| PDF Services sandbox blocks USB | LaunchAgent worker runs in the full user session |
| PDF Services sandbox blocks Homebrew binaries | Only use shell builtins and Apple-native file operations in the PDF Services script |
| Multi-page PDFs must print every page | Queue the original PDF, then render pages with PyMuPDF in the worker and print one label per page |
| PDF Services sandbox blocks `launchctl` | Use LaunchAgent `WatchPaths` on `/tmp/ql800_pending` |
| Launchd does not expand env vars in plists | Makefile substitutes `__INSTALL_DIR__` via `sed` |
| Repo may not live at `~/ql800` | Runtime paths point at the installed Application Support directory |
| Missing venv causes delayed runtime failure | `make deploy` creates and checks the installed venv before launching |
| `brother_ql` CUPS backend removed | Use the `pyusb` backend exclusively |
| PDF path is last arg, not `$1` | Use `${@: -1}` in the PDF Services script |
