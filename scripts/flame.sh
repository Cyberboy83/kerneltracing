#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  DebianTrace Pro — FlameGraph generator
#  Usage: sudo flame.sh <pid> [output.svg] [duration_sec]
#  Example: sudo flame.sh 1234 /tmp/myapp.svg 30
# ══════════════════════════════════════════════════════════════════
set -euo pipefail

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo $0 <pid> [output.svg] [duration]"; exit 1; }

PID="${1:?Usage: sudo flame.sh <pid> [output.svg] [duration_seconds]}"
OUTPUT="${2:-/tmp/flame-$(date +%s).svg}"
DURATION="${3:-10}"

FLAMEGRAPH_DIR="/opt/FlameGraph"
if [[ ! -f "$FLAMEGRAPH_DIR/flamegraph.pl" ]]; then
  echo "Error: FlameGraph not found at $FLAMEGRAPH_DIR"
  echo "Install: git clone https://github.com/brendangregg/FlameGraph $FLAMEGRAPH_DIR"
  exit 1
fi

echo "Recording PID $PID for ${DURATION}s at 99Hz..."
perf record -a -g -F 99 -p "$PID" -- sleep "$DURATION" -o /tmp/perf.data 2>/dev/null

echo "Generating flamegraph..."
perf script -i /tmp/perf.data | \
  "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" | \
  "$FLAMEGRAPH_DIR/flamegraph.pl" > "$OUTPUT"

rm -f /tmp/perf.data /tmp/perf.data.old

echo "✔ Flamegraph saved: $OUTPUT"
xdg-open "$OUTPUT" 2>/dev/null || echo "Open in browser: $OUTPUT"
