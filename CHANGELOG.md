# Changelog

All notable changes to **DebianTrace Pro** will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
This project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- ARM64 / aarch64 support
- Ansible playbook alternative installer
- Pre-built Grafana dashboard JSON files for kernel tracing
- Automated CI test suite with `bats`
- eBPF program examples directory

---

## [1.0.0] — 2024-01-01

### Added
- 13-phase automated installer for Debian 12 Bookworm
- eBPF/bpftrace/BCC full toolchain install
- perf + Brendan Gregg FlameGraph integration
- ftrace / trace-cmd / kernelshark setup
- SystemTap with DWARF support
- Valgrind, heaptrack, massif-visualizer
- Network tracing: Wireshark, tshark, tcpdump, nethogs, iperf3
- Python scientific stack: NumPy, Polars, Dask, Plotly, scikit-learn, JupyterLab
- R + ggplot2 statistical computing
- Apache Spark 3.5.1 with PySpark
- Full observability Docker Compose: Grafana + Prometheus + ClickHouse + Loki + Tempo
- Node Exporter with all optional collectors enabled
- cAdvisor for container metrics
- oh-my-zsh + powerlevel10k + zsh-autosuggestions + syntax highlighting
- 50+ tracing shell aliases and helper functions
- Professional tmux config with tracing workspace layouts
- Kernel sysctl tuning (BPF JIT, perf paranoid, tracefs)
- `trace-mode-on` / `trace-mode-off` scripts
- VS Code with C/C++, Python, Go, Rust, Jupyter extensions
- Neovim with vim-plug
- Go 1.22 + cilium/ebpf toolchain
- Rust stable + Aya eBPF framework
- XFCE4 desktop (optional, `--skip-gui` to bypass)
- Quick reference documentation and cheatsheet
- `--headless`, `--skip-gui`, `--minimal` installer flags
- Per-run install log at `/var/log/debian-trace-setup-*.log`
