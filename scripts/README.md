# Scripts

Utility scripts installed to `/usr/local/bin/` by `install.sh`. Can also be run directly.

## trace-mode-on.sh

Switches the system into high-performance tracing mode:
- CPU governor → `performance`
- Disables NMI watchdog (reduces profiling noise)
- Mounts debugfs, tracefs, and bpffs if not already mounted
- Clears trace buffers
- Enables BPF JIT

```bash
sudo bash scripts/trace-mode-on.sh
# or after install:
sudo trace-mode-on
```

## trace-mode-off.sh

Restores normal operating mode:
- CPU governor → `powersave`
- Re-enables NMI watchdog
- Disables ftrace

```bash
sudo bash scripts/trace-mode-off.sh
# or after install:
sudo trace-mode-off
```

## flame.sh

Generates a FlameGraph SVG for a given PID.

```bash
# Usage: sudo flame.sh <pid> [output.svg] [duration_seconds]
sudo bash scripts/flame.sh 1234 /tmp/myapp.svg 30
```

Requires: `perf`, `stackcollapse-perf.pl`, `flamegraph.pl` (installed at `/opt/FlameGraph`)

## uninstall.sh

Partial uninstall — removes configs and `/opt` directories.  
Does **not** remove apt-installed packages.

```bash
sudo bash scripts/uninstall.sh
```
