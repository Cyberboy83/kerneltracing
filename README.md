<div align="center">

```
██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗    ████████╗██████╗  █████╗  ██████╗███████╗
██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║    ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝
██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║       ██║   ██████╔╝███████║██║     █████╗
██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║       ██║   ██╔══██╗██╔══██║██║     ██╔══╝
██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║       ██║   ██║  ██║██║  ██║╚██████╗███████╗
╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝       ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝
```

### Kernel Tracing & Data Analysis Workstation — Professional Edition

[![Debian](https://img.shields.io/badge/Debian-12%20Bookworm-A81D33?style=flat-square&logo=debian&logoColor=white)](https://www.debian.org/)
[![Kernel](https://img.shields.io/badge/Kernel-6.x%20%2B%20eBPF-00d4ff?style=flat-square&logo=linux&logoColor=white)](https://kernel.org/)
[![Shell](https://img.shields.io/badge/Shell-Bash%205-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-8b5cf6?style=flat-square)](./LICENSE)
[![Phases](https://img.shields.io/badge/Install%20Phases-13-f59e0b?style=flat-square)](#installation-phases)
[![Stars](https://img.shields.io/github/stars/youruser/debian-trace-pro?style=flat-square&color=f59e0b)](https://github.com/youruser/debian-trace-pro/stargazers)

**One script. 13 phases. From bare Debian to a complete kernel tracing and data analysis workstation.**

eBPF · bpftrace · BCC · perf · ftrace · SystemTap · Grafana · Prometheus · ClickHouse · Spark · JupyterLab

[**Quick Start**](#-quick-start) · [**What's Installed**](#-whats-installed) · [**Usage**](#-usage) · [**Observability Stack**](#-observability-stack) · [**Docs**](#-documentation) · [**Contributing**](#-contributing)

</div>

---

## Overview

**DebianTrace Pro** transforms a stock Debian 12 (Bookworm) system into a fully loaded, real-world-ready workstation for:

- **Kernel tracing** — eBPF programs, bpftrace one-liners, BCC tools, ftrace, SystemTap
- **Performance profiling** — CPU flamegraphs, PMU counters, scheduler latency, lock contention, memory analysis
- **Network analysis** — Wireshark, XDP/eBPF, tcplife, tcptop, packet capture pipelines
- **Data science** — JupyterLab, Apache Spark, ClickHouse, Python & R scientific stacks
- **Observability** — Grafana + Prometheus + Loki + Tempo + ClickHouse, pre-wired via Docker Compose

Every tool is pre-configured, aliased, and ready from the first shell session. No dependency hunting. No manual configuration. No guesswork.

---

## ⚡ Quick Start

```bash
# Clone the repo
git clone https://github.com/youruser/debian-trace-pro.git
cd debian-trace-pro

# Run as root on Debian 12 Bookworm
sudo bash install.sh
```

> **Requirements:** Debian 12 Bookworm · x86\_64 · Root access · ~20 GB free disk · Internet connection

### Flags

| Flag | Description |
|------|-------------|
| `--headless` | Skip all prompts — fully automated (CI / unattended installs) |
| `--skip-gui` | Skip XFCE desktop — ideal for servers and VMs |
| `--minimal` | Core tracing tools only — no Spark, ClickHouse, or desktop |
| `--help` | Show usage |

```bash
# Examples
sudo bash install.sh --headless --skip-gui   # server / CI
sudo bash install.sh --minimal               # tracing only, fast
sudo bash install.sh                         # full interactive install
```

---

## 📦 What's Installed

### Installation Phases

| # | Phase | Key Tools |
|---|-------|-----------|
| `01` | System Foundation | gcc, clang, git, zsh, tmux, btop, fzf, ripgrep, fd, bat |
| `02` | Kernel Headers & BPF | linux-headers, libbpf-dev, bpftrace, bpfcc-tools, bpftool |
| `03` | Tracing Arsenal | perf, FlameGraph, trace-cmd, kernelshark, ftrace, SystemTap, Valgrind |
| `04` | eBPF Dev Environment | clang/LLVM, libbpf, Go + cilium/ebpf, Rust + Aya framework |
| `05` | Data Science Stack | Python (NumPy · Polars · Dask · Plotly · scikit-learn), R, JupyterLab, Apache Spark 3.5 |
| `06` | Observability Stack | Grafana, Prometheus, ClickHouse, Loki, Tempo, Node Exporter, cAdvisor |
| `07` | IDE & Dev Tools | VS Code + extensions, Neovim + LSP, vim-plug |
| `08` | Shell Environment | oh-my-zsh, powerlevel10k, 50+ tracing aliases, helper functions |
| `09` | Kernel Tuning | BPF JIT, perf paranoid=1, tracefs mount, CPU performance governor |
| `10` | tmux Config | Professional status bar, tracing layouts, TPM plugin manager |
| `11` | Documentation | Quick reference at `~/TRACE-QUICKREF.md` |
| `12` | Desktop *(optional)* | XFCE4 + LightDM |
| `13` | Final Services | SSH, BPF fs, autoremove, cleanup |

### Tracing Tools

| Tool | What it does |
|------|-------------|
| `bpftrace` | High-level eBPF tracing language — kprobes, uprobes, tracepoints, perf events |
| BCC (60+ tools) | execsnoop, opensnoop, biolatency, memleak, offcputime, tcplife, profile… |
| `perf` + FlameGraph | CPU/PMU profiling, flamegraph generation, scheduler & lock analysis |
| `ftrace` / `trace-cmd` | Built-in kernel function & event tracer with kernelshark GUI |
| SystemTap | Scripted kernel instrumentation with DWARF support |
| Valgrind / heaptrack | memcheck, callgrind, massif heap profiling |
| Wireshark / tshark | Packet capture and deep protocol analysis |
| `strace` / `ltrace` | Syscall and library call tracing |
| `py-spy` / `memray` | Python-specific CPU and memory profilers |

---

## 💻 Usage

### Observability Stack

```bash
obs-up        # Start Grafana + Prometheus + ClickHouse + Loki + Tempo
obs-status    # Container health check
obs-down      # Stop everything
```

Open **Grafana** → http://localhost:3000 (`admin` / `tracepro2024`)

---

### eBPF / bpftrace

```bash
# Built-in aliases — available immediately after install
bt-syscalls   # Count syscalls by process (live eBPF)
bt-openat     # Trace all file opens: process + filename
bt-execve     # Trace every new process execution
bt-biodist    # Block I/O latency histogram
bt-oomkill    # Watch for OOM kill events
bt-tcpconn    # TCP connection tracing
bt-malloc     # malloc allocation size distribution (uprobe)
bt-profile    # CPU profiling by kernel stack (99 Hz)

# Custom one-liner
sudo bpftrace -e '
  tracepoint:syscalls:sys_enter_openat {
    printf("%s %s\n", comm, str(args->filename));
  }'
```

---

### perf + FlameGraph

```bash
perf-cpu      # Live CPU top — all CPUs, call graphs
perf-flame    # 10s capture → flamegraph SVG (auto-opens)
perf-cache    # L1/L2/LLC cache miss statistics
perf-sched    # Scheduler wake-up latency report
perf-mem      # Memory access pattern analysis
perf-lock     # Lock contention report

# Custom flamegraph for a specific PID
flame 1234 /tmp/myapp.svg 30    # <pid> <output> <duration_sec>
```

---

### BCC Tools

```bash
bcc-execsnoop     # New process executions
bcc-opensnoop     # File opens
bcc-biolatency    # Block I/O latency histogram
bcc-memleak       # Memory leak detection
bcc-offcputime    # Off-CPU time profiling
bcc-profile       # CPU profiling (user + kernel stacks)
bcc-tcplife       # TCP session lifespan + bytes
bcc-capable       # Linux capability (CAP_*) audit trace
bcc-ext4slower    # Slow ext4 filesystem operations
bcc-tcptop        # TCP bandwidth top
```

---

### ftrace

```bash
ftrace-start      # Enable kernel function tracer
ftrace-read       # Print trace buffer
ftrace-events     # List all available kernel events
ftrace-stop       # Disable tracer
ftrace-clear      # Clear trace buffer

# Full trace-cmd workflow
sudo trace-cmd record -p function_graph -g do_sys_open sleep 5
sudo trace-cmd report
kernelshark       # GUI visualization
```

---

### Data Analysis

```bash
jupyter           # Launch JupyterLab at http://localhost:8888
pyspark           # Apache Spark Python shell
spark-shell       # Apache Spark Scala shell
ch                # ClickHouse client (Docker or local)
```

---

### tmux Quick Layouts

> Prefix is `Ctrl-a`

| Shortcut | Layout |
|----------|--------|
| `Ctrl-a T` | Tracing workspace: btop + live dmesg + bpftrace syscall counter |
| `Ctrl-a D` | Data workspace: JupyterLab + terminal |
| `Ctrl-a O` | Observability workspace: start obs stack |
| `Ctrl-a \|` | Split pane horizontally |
| `Ctrl-a -` | Split pane vertically |

---

### Performance Mode

```bash
sudo trace-mode-on    # Performance governor + disable NMI watchdog + clear trace buffers
sudo trace-mode-off   # Restore power-saving governor + re-enable watchdog
```

---

## 🔭 Observability Stack

All services run via Docker Compose at `/opt/observability/`.

```
┌──────────────────────────────────────────────────────────────────┐
│                        Grafana  :3000                            │
│               Dashboards · Alerts · Explore · Trace              │
└────────┬───────────────┬──────────────┬──────────────────────────┘
         │               │              │
    Prometheus        ClickHouse      Loki              Tempo
      :9090             :8123         :3100             :3200
         │
  Node Exporter + cAdvisor
     :9100         :8080
```

| Service | URL | Credentials | Purpose |
|---------|-----|-------------|---------|
| Grafana | http://localhost:3000 | `admin` / `tracepro2024` | Dashboards & alerts |
| Prometheus | http://localhost:9090 | — | Metrics & PromQL |
| ClickHouse | http://localhost:8123 | `default` / *(no password)* | High-speed event analytics |
| Loki | http://localhost:3100 | — | Log aggregation |
| Tempo | http://localhost:3200 | — | Distributed tracing |
| Node Exporter | http://localhost:9100 | — | Host metrics |
| cAdvisor | http://localhost:8080 | — | Container metrics |

> **Note:** ClickHouse has no authentication by default. Add credentials before exposing to a network.

---

## 🗂️ Repository Structure

```
debian-trace-pro/
│
├── install.sh                          ← Main installer — run this
│
├── configs/
│   ├── zsh/.zshrc                      ← 50+ tracing aliases (standalone)
│   ├── tmux/.tmux.conf                 ← Professional tmux config
│   └── sysctl/99-trace-pro.conf        ← Kernel tuning (BPF JIT, perf, tracefs)
│
├── observability/
│   ├── docker-compose.yml              ← Full 7-service stack
│   ├── prometheus/prometheus.yml
│   ├── clickhouse/config.xml
│   ├── loki/loki-config.yml
│   ├── tempo/tempo-config.yml
│   └── grafana/provisioning/
│       └── datasources/datasources.yml
│
├── scripts/
│   ├── trace-mode-on.sh                ← Enable high-performance tracing mode
│   ├── trace-mode-off.sh               ← Restore normal mode
│   ├── flame.sh                        ← Flamegraph generator helper
│   └── uninstall.sh                    ← Partial uninstall
│
├── docs/
│   ├── QUICKREF.md                     ← Full command cheatsheet
│   ├── TRACING_COOKBOOK.md             ← 9 real-world tracing recipes
│   ├── EBPF_GUIDE.md                   ← bpftrace → BCC → libbpf → Go → Rust
│   └── dashboard.html                  ← Visual reference card (open in browser)
│
├── .github/
│   ├── workflows/lint.yml              ← ShellCheck + Markdown lint CI
│   ├── ISSUE_TEMPLATE/bug_report.md
│   ├── ISSUE_TEMPLATE/feature_request.md
│   └── PULL_REQUEST_TEMPLATE.md
│
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [QUICKREF.md](docs/QUICKREF.md) | Complete command cheatsheet for every tool |
| [TRACING\_COOKBOOK.md](docs/TRACING_COOKBOOK.md) | 9 real-world recipes: CPU, I/O, memory, network, scheduler, containers |
| [EBPF\_GUIDE.md](docs/EBPF_GUIDE.md) | Writing eBPF in bpftrace, BCC, libbpf C, Go (cilium/ebpf), and Rust (Aya) |
| [dashboard.html](docs/dashboard.html) | Visual reference card — open in any browser |

---

## 🔒 Security Notes

- `kernel.perf_event_paranoid = 1` — non-root perf allowed; raw tracepoints require privileges
- `kernel.kptr_restrict = 0` — kernel pointers exposed for symbol resolution; **revert to `1` in hardened environments**
- A `tracing` group is created; add users with `usermod -aG tracing <user>` for non-root tracing
- eBPF programs still require `CAP_BPF` or root
- ClickHouse and Grafana use default credentials — **change before exposing to any network**

---

## 🛠️ eBPF Development

The full eBPF development chain is installed and ready:

```bash
# bpftrace — quickest path
sudo bpftrace -e 'kprobe:do_sys_openat2 { printf("%s\n", comm); }'

# BCC Python — feature-rich tools
sudo python3 /opt/bpf-perf-tools/opensnoop.py

# libbpf C — CO-RE portable programs
clang -O2 -target bpf -c tracer.bpf.c -o tracer.bpf.o

# Go + cilium/ebpf
go generate ./...
go build -o tracer .

# Rust + Aya
cargo xtask run
```

See [docs/EBPF\_GUIDE.md](docs/EBPF_GUIDE.md) for full examples in all four languages.

---

## 🤝 Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

```bash
# After making changes, lint before opening a PR
shellcheck install.sh scripts/*.sh
```

**Areas that need help:**
- ARM64 / aarch64 support
- Pre-built Grafana dashboard JSON files
- eBPF program examples directory
- Ansible playbook alternative installer
- Automated `bats` test suite

---

## 🙏 Credits

This project stands on the shoulders of exceptional open-source work:

- [**Brendan Gregg**](https://brendangregg.com/) — FlameGraph, BCC, bpftrace, perf-tools, *BPF Performance Tools* book
- [**Cilium**](https://cilium.io/) — cilium/ebpf Go library
- [**iovisor/BCC**](https://github.com/iovisor/bcc) — BPF Compiler Collection
- [**Grafana Labs**](https://grafana.com/) — Grafana, Loki, Tempo
- [**ClickHouse**](https://clickhouse.com/) — Columnar analytics database

---

## 📜 License

MIT License — see [LICENSE](LICENSE) for details. Free to use, modify, and distribute.

---

<div align="center">

Built for kernel engineers, performance analysts, and systems researchers.

**[⭐ Star this repo](https://github.com/youruser/debian-trace-pro)** if it saved you setup time.

</div>
