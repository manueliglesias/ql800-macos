#!/bin/bash
# Runs inside the PDF Services sandbox. Only Apple-native tools are used here.

LOG="/tmp/ql800_debug.log"
exec >> "$LOG" 2>&1
echo "=== $(date) ==="

PDF="${@: -1}"
PNG="/tmp/ql800_pending/job_$$.png"

mkdir -p /tmp/ql800_pending

sips -s format png "$PDF" --out "$PNG"
echo "sips exit: $?"
echo "Done"
