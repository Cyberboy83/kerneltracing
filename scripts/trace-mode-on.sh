#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  DebianTrace Pro — Enable high-performance tracing mode
#  Sets CPU to performance governor, disables NMI watchdog,
#  clears trace buffers, and mounts required filesystems.
# ══════════════════════════════════════════════════════════════════
set -euo pipefail

[[ $EUID -ne 0 ]] && { echo "Run as root: sudo trace-mode-on"; exit 1; }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DebianTrace Pro — Enabling Tracing Mode"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# CPU governor → performance
echo "Setting CPU governor: performance..."
for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance > "$gov" 2>/dev/null || true
done

# Disable NMI watchdog (reduces profiling noise)
echo "Disabling NMI watchdog..."
echo 0 > /proc/sys/kernel/nmi_watchdog 2>/dev/null || true
echo 0 > /proc/sys/kernel/watchdog     2>/dev/null || true

# Mount debugfs and tracefs if not mounted
mountpoint -q /sys/kernel/debug  || mount -t debugfs  debugfs  /sys/kernel/debug  2>/dev/null || true
mountpoint -q /sys/kernel/tracing || mount -t tracefs tracefs /sys/kernel/tracing 2>/dev/null || true
mountpoint -q /sys/fs/bpf         || mount -t bpf     bpffs   /sys/fs/bpf         2>/dev/null || true

# Clear trace buffer
echo "Clearing trace buffers..."
echo 0 > /sys/kernel/debug/tracing/tracing_on    2>/dev/null || true
echo > /sys/kernel/debug/tracing/trace           2>/dev/null || true
echo nop > /sys/kernel/debug/tracing/current_tracer 2>/dev/null || true

# Enable BPF JIT
echo 1 > /proc/sys/net/core/bpf_jit_enable 2>/dev/null || true

echo ""
echo "✔ Tracing mode: ENABLED"
echo "  • CPU governor: performance"
echo "  • NMI watchdog: disabled"
echo "  • debugfs: mounted at /sys/kernel/debug"
echo "  • tracefs: mounted at /sys/kernel/tracing"
echo "  • bpffs:   mounted at /sys/fs/bpf"
echo "  • BPF JIT: enabled"
echo ""
echo "Run 'sudo trace-mode-off' to restore defaults."
