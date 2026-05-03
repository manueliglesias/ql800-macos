#!/bin/bash
# Runs outside the PDF Services sandbox via LaunchAgent.

LOG="/tmp/ql800_worker.log"
exec >> "$LOG" 2>&1
echo "=== $(date) === worker fired"

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p /tmp/ql800_pending

for f in /tmp/ql800_pending/*.png; do
    [ -f "$f" ] || continue
    echo "Printing: $f"
    "$INSTALL_DIR/.venv/bin/python3" "$INSTALL_DIR/print_label.py" "$f"
    echo "python exit: $?"
    rm -f "$f"
done

echo "Worker done"
