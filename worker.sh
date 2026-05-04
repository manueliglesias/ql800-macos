#!/bin/bash
# Runs outside the PDF Services sandbox via LaunchAgent.

LOG="/tmp/ql800_worker.log"
exec >> "$LOG" 2>&1
echo "=== $(date) === worker fired"

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
QUEUE_DIR="/tmp/ql800_pending"
FAILED_DIR="$QUEUE_DIR/failed"
LOCK_DIR="/tmp/dev.iglesias.ql800.worker.lock"

mkdir -p "$QUEUE_DIR"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    echo "Another worker is already running"
    exit 0
fi
trap 'rmdir "$LOCK_DIR"' EXIT

while IFS= read -r f; do
    [ -f "$f" ] || continue
    echo "Printing: $f"
    "$INSTALL_DIR/.venv/bin/python3" "$INSTALL_DIR/print_label.py" "$f"
    status=$?
    echo "python exit: $status"

    if [ "$status" -eq 0 ]; then
        rm -f "$f"
    else
        mkdir -p "$FAILED_DIR"
        failed="$FAILED_DIR/$(basename "$f").failed_$(date +%Y%m%d%H%M%S)"
        echo "Moving failed job to: $failed"
        mv "$f" "$failed"
    fi
done < <(find "$QUEUE_DIR" -maxdepth 1 -type f \( -name '*.pdf' -o -name '*.png' \) | sort)

echo "Worker done"
