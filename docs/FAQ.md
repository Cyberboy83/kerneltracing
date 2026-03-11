# Frequently Asked Questions

---

**Q: Does this work on Ubuntu or other Debian-based distros?**

It was written and tested for Debian 12 Bookworm. Ubuntu 22.04/24.04 will work for most phases but package names differ for some kernel tools (e.g., `linux-tools-$(uname -r)` vs `linux-perf`). Ubuntu support is on the roadmap.

---

**Q: Does this work on ARM64 / Apple Silicon?**

Not yet. x86\_64 only for now. ARM64 support is a planned contribution — see [CONTRIBUTING.md](../CONTRIBUTING.md).

---

**Q: Do I need to run this on a bare-metal machine?**

No. VMs work fine. You lose hardware PMU counters (perf cache stats, TurboStat) inside a VM, but eBPF tracing, BCC tools, bpftrace, ftrace, and the observability stack all work fully in a VM.

---

**Q: Can I run this on a machine I'm already using?**

Yes, but read `install.sh` first. It modifies sysctl settings, installs many packages, and changes your shell to zsh. Use `--minimal` to limit the scope if you want to keep your environment mostly intact.

---

**Q: Why does the installer need root?**

Installing kernel headers, BPF tools, sysctl tuning, mounting debugfs/tracefs/bpffs, and setting up Docker all require root. The installer uses `sudo` internally where possible, but the outer script must be run as root.

---

**Q: Can I run the observability stack on a separate machine?**

Yes. Copy the `observability/` directory to the target machine, edit the `prometheus.yml` scrape targets to point at your tracing host's IP, and run `docker compose up -d` there.

---

**Q: How do I update DebianTrace Pro?**

```bash
git pull
sudo bash install.sh --headless --skip-gui
```

The installer is designed to be re-run safely — it checks for existing installations and skips completed work.

---

**Q: What is the performance overhead of running bpftrace / BCC in production?**

eBPF programs run in the kernel with JIT compilation. A simple counter or histogram typically adds less than 1–2% CPU overhead. Aggressive tracing (e.g., profiling at 99 Hz across all CPUs) can add 3–5%. Always benchmark on a staging system before running heavy tracing in production.

---

**Q: How do I add a custom Grafana dashboard?**

Place your dashboard JSON file in `observability/grafana/provisioning/dashboards/` and add a `dashboards.yml` provisioning config in the same directory. On next `obs-up`, Grafana will load it automatically.

---

**Q: The default ClickHouse password is empty — is that safe?**

For a local workstation it is fine. Before exposing ClickHouse to any network, add a password in `/opt/observability/clickhouse/config.xml` and restart the container.

---

**Q: I want to write my own eBPF program — where do I start?**

See [docs/EBPF\_GUIDE.md](EBPF_GUIDE.md). It covers bpftrace scripts, BCC Python programs, libbpf C (CO-RE), Go with cilium/ebpf, and Rust with Aya — from simple one-liners to full production agents.

---

**Q: How do I stream trace events into ClickHouse?**

See the "Ingest Trace Data into ClickHouse" recipe in [docs/TRACING\_COOKBOOK.md](TRACING_COOKBOOK.md). The short version: pipe `bpftrace -f json` output into `clickhouse-client --query "INSERT INTO ... FORMAT JSONEachRow"`.

---

**Q: Can I use this for security auditing / blue team work?**

Absolutely. bpftrace and BCC are excellent for auditing capability usage (`bcc-capable`), detecting unexpected `execve` calls (`bcc-execsnoop`), monitoring network connections (`bt-tcpconn`), and watching for privilege escalation attempts. The observability stack can retain and alert on these events over time.
