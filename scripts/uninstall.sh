#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
#  DebianTrace Pro — Partial uninstall helper
#  Removes configs and opt directories; does NOT remove system packages
# ══════════════════════════════════════════════════════════════════
set -euo pipefail

[[ $EUID -ne 0 ]] && { echo "Run as root."; exit 1; }

echo "This will remove DebianTrace Pro configs and /opt directories."
echo "It will NOT remove apt-installed packages (bpftrace, perf, etc.)"
read -rp "Continue? [y/N]: " CONFIRM
[[ "${CONFIRM,,}" != "y" ]] && exit 0

echo "Removing /opt/FlameGraph..."
rm -rf /opt/FlameGraph

echo "Removing /opt/perf-tools..."
rm -rf /opt/perf-tools

echo "Removing /opt/bpf-perf-tools..."
rm -rf /opt/bpf-perf-tools

echo "Removing /opt/spark..."
rm -rf /opt/spark

echo "Removing /opt/observability..."
cd /opt/observability && docker compose down --volumes 2>/dev/null || true
rm -rf /opt/observability

echo "Removing /opt/trace-docs..."
rm -rf /opt/trace-docs

echo "Removing sysctl config..."
rm -f /etc/sysctl.d/99-trace-pro.conf
sysctl -p 2>/dev/null || true

echo "Removing trace-mode scripts..."
rm -f /usr/local/bin/trace-mode-on /usr/local/bin/trace-mode-off

echo ""
echo "✔ DebianTrace Pro configs removed."
echo "  To remove apt packages: sudo apt remove bpfcc-tools bpftrace linux-perf trace-cmd systemtap valgrind wireshark"
