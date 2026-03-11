# Installation Guide

Detailed installation instructions for DebianTrace Pro across different environments.

---

## Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| OS | Debian 12 Bookworm | Debian 12 Bookworm (fresh install) |
| Architecture | x86\_64 | x86\_64 |
| RAM | 4 GB | 16 GB+ |
| Disk | 20 GB free | 100 GB+ SSD |
| Internet | Required | Fast broadband |
| Privileges | Root / sudo | Root |
| Kernel | 5.15+ | 6.1+ (for full eBPF support) |

---

## Installation Methods

### Method 1 — Full Install (Recommended)

```bash
git clone https://github.com/youruser/debian-trace-pro.git
cd debian-trace-pro
sudo bash install.sh
```

Installs all 13 phases interactively. Approximately 30–60 minutes.

---

### Method 2 — Server / Headless

```bash
sudo bash install.sh --headless --skip-gui
```

No prompts, no desktop. Ideal for bare-metal servers, VMs, and CI systems.

---

### Method 3 — Core Tracing Only

```bash
sudo bash install.sh --minimal --headless
```

Installs only the kernel tracing layer (Phases 1–4, 8–11). Skips Spark, ClickHouse, and desktop. Fastest option — under 15 minutes on a good connection.

---

### Method 4 — Make Targets

```bash
make install           # Full interactive
make install-server    # Headless, no GUI
make install-minimal   # Core tracing only
```

---

## Virtual Machine Setup

DebianTrace Pro works well inside VMs with a few considerations:

**VirtualBox / VMware:**
- Enable **nested virtualisation** if you plan to run Docker inside the VM
- Allocate at least **4 CPU cores** for meaningful perf data
- Use a **bridged network adapter** if you want to access Grafana from the host

**Checking kernel BPF support inside a VM:**
```bash
# Should return y or m for all
zcat /proc/config.gz | grep -E "CONFIG_BPF|CONFIG_DEBUG_INFO_BTF"

# Check BTF is available (required for CO-RE eBPF)
ls /sys/kernel/btf/vmlinux
```

If `/sys/kernel/btf/vmlinux` is missing, some eBPF CO-RE programs won't work. The installer warns about this but continues.

---

## WSL2 Setup

eBPF tracing is limited on WSL2 because the Microsoft kernel does not expose all tracepoints. Basic bpftrace scripts work; kprobes and some BCC tools may not.

```bash
# Check your WSL kernel version
uname -r   # Should be 5.15+ for best eBPF support

# Install on WSL2 (skip GUI and some kernel tools)
sudo bash install.sh --headless --skip-gui --minimal
```

For full kernel tracing capability, use a native Linux machine or a proper VM.

---

## Post-Install Steps

### 1. Reboot

```bash
sudo reboot
```

Required to apply sysctl changes, group membership updates, and BPF filesystem mounts.

### 2. Start the Observability Stack

```bash
obs-up
```

Opens Grafana at http://localhost:3000 — change the default password immediately.

### 3. Verify eBPF Works

```bash
# Should print syscall counts immediately
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); } interval:s:2 { print(@); clear(@); }'
```

### 4. Run a Test Flamegraph

```bash
# Profile the system for 10 seconds
perf-flame
# Opens /tmp/flame-*.svg in your browser
```

### 5. Read the Quick Reference

```bash
cat ~/TRACE-QUICKREF.md | less
```

---

## Uninstalling

```bash
sudo bash scripts/uninstall.sh
```

This removes configs, `/opt` directories, and the observability Docker stack. It does **not** remove apt packages. To also remove packages:

```bash
sudo apt remove bpfcc-tools bpftrace linux-perf trace-cmd systemtap valgrind wireshark
sudo apt autoremove
```

---

## Troubleshooting

### `bpftrace: cannot attach probe` errors

```bash
# Check perf_event_paranoid level
cat /proc/sys/kernel/perf_event_paranoid
# Should be 1 or lower. If higher:
sudo sysctl -w kernel.perf_event_paranoid=1
```

### `debugfs not mounted` errors

```bash
sudo mount -t debugfs debugfs /sys/kernel/debug
sudo mount -t tracefs tracefs /sys/kernel/tracing
```

These are added to `/etc/fstab` during install, so a reboot should fix it permanently.

### `No BTF data found` errors

Your kernel may not have been compiled with `CONFIG_DEBUG_INFO_BTF=y`. Check:

```bash
zcat /proc/config.gz | grep CONFIG_DEBUG_INFO_BTF
```

If missing, install the debug kernel or use a distribution kernel that includes BTF (Debian's official kernel includes it from 5.10+).

### Docker / Observability stack fails to start

```bash
# Check Docker is running
sudo systemctl status docker

# Check logs for the failing container
cd /opt/observability && docker compose logs prometheus
```

### `perf: command not found`

```bash
sudo apt install linux-perf linux-tools-$(uname -r) linux-tools-common
```

### ClickHouse won't start (port conflict)

Port 9000 may be in use by another service. Edit `/opt/observability/docker-compose.yml` and change the ClickHouse native port mapping:

```yaml
ports:
  - "8123:8123"
  - "19000:9000"   # change host port
```
