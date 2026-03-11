# Configs

Standalone configuration files. These are deployed automatically by `install.sh` but can also be applied manually.

## zsh — `configs/zsh/.zshrc`

Full zsh configuration with 50+ tracing aliases and helper functions.

**Apply manually:**
```bash
cp configs/zsh/.zshrc ~/.zshrc
source ~/.zshrc
```

**Requires:** oh-my-zsh, powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting

## tmux — `configs/tmux/.tmux.conf`

Professional tmux config with a dark tracing-themed status bar, custom keybindings, and quick workspace layouts.

**Apply manually:**
```bash
cp configs/tmux/.tmux.conf ~/.tmux.conf
tmux source ~/.tmux.conf
```

**Key bindings (prefix: `Ctrl-a`):**

| Key | Action |
|-----|--------|
| `Ctrl-a T` | Open tracing workspace (btop + dmesg + bpftrace) |
| `Ctrl-a D` | Open data workspace (JupyterLab) |
| `Ctrl-a \|` | Split pane horizontal |
| `Ctrl-a -` | Split pane vertical |
| `Ctrl-a h/j/k/l` | Navigate panes |

## sysctl — `configs/sysctl/99-trace-pro.conf`

Kernel parameter tuning for profiling and eBPF tracing.

**Apply manually:**
```bash
sudo cp configs/sysctl/99-trace-pro.conf /etc/sysctl.d/
sudo sysctl -p /etc/sysctl.d/99-trace-pro.conf
```

**Key settings:**

| Parameter | Value | Why |
|-----------|-------|-----|
| `net.core.bpf_jit_enable` | `1` | JIT compile eBPF for performance |
| `kernel.perf_event_paranoid` | `1` | Allow non-root perf usage |
| `kernel.kptr_restrict` | `0` | Expose kernel pointers for symbol resolution |
| `kernel.ftrace_enabled` | `1` | Enable ftrace subsystem |
| `kernel.nmi_watchdog` | `0` | Reduce profiling noise |
| `kernel.sched_schedstats` | `1` | Enable scheduler statistics |
