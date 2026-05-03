#!/bin/bash
# Runs inside the PDF Services sandbox. Keep this limited to Apple-native file
# operations; rendering and USB access happen in the LaunchAgent worker.

LOG="/tmp/ql800_debug.log"
exec >> "$LOG" 2>&1
echo "=== $(date) ==="

PDF="${@: -1}"
QUEUE_DIR="/tmp/ql800_pending"

mkdir -p "$QUEUE_DIR"

TMP="$(mktemp "$QUEUE_DIR/.job_$$_XXXXXX")"
TMP_BASE="$(basename "$TMP")"
JOB="$QUEUE_DIR/job_$(date +%Y%m%d%H%M%S)_$$_${TMP_BASE##*_}.pdf"

cp "$PDF" "$TMP"
cp_exit=$?
echo "cp exit: $cp_exit"
if [ "$cp_exit" -ne 0 ]; then
    rm -f "$TMP"
    exit "$cp_exit"
fi

mv "$TMP" "$JOB"
mv_exit=$?
echo "mv exit: $mv_exit"
if [ "$mv_exit" -ne 0 ]; then
    rm -f "$TMP"
    exit "$mv_exit"
fi
echo "Queued: $JOB"
echo "Done"
