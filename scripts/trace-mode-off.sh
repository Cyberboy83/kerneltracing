#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  DebianTrace Pro — Restore normal operating mode
# ══════════════════════════════════════════════════════════════════
set -euo pipefail

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo trace-mode-off"; exit 1; }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DebianTrace Pro — Restoring Normal Mode"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# CPU governor → powersave
echo "Restoring CPU governor: powersave..."
for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo powersave > "$gov" 2>/dev/null || true
done

# Re-enable watchdog
echo "Re-enabling NMI watchdog..."
echo 1 > /proc/sys/kernel/nmi_watchdog 2>/dev/null || true
echo 1 > /proc/sys/kernel/watchdog     2>/dev/null || true

# Disable tracing
echo 0 > /sys/kernel/debug/tracing/tracing_on    2>/dev/null || true
echo nop > /sys/kernel/debug/tracing/current_tracer 2>/dev/null || true

echo ""
echo "✔ Normal mode restored."
