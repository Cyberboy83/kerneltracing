# eBPF Development Guide

A practical guide to writing, compiling, and loading eBPF programs on DebianTrace Pro.

---

## Prerequisites (already installed by `install.sh`)

- `clang` / `llvm` — eBPF bytecode compiler
- `libbpf-dev` — Portable BPF library
- `linux-headers-$(uname -r)` — Kernel headers
- Go 1.22+ with `cilium/ebpf` toolchain
- Rust stable with `aya` framework

---

## bpftrace — Highest Level

Best for: quick one-liners, exploratory tracing, production scripts.

```bash
# Syntax: probespec { actions }
# Probe types: kprobe, kretprobe, uprobe, uretprobe,
#              tracepoint, software, hardware, profile, interval

# Example: latency histogram for write() syscall
sudo bpftrace -e '
  tracepoint:syscalls:sys_enter_write { @start[tid] = nsecs; }
  tracepoint:syscalls:sys_exit_write  /@start[tid]/ {
    @latency_us = hist((nsecs - @start[tid]) / 1000);
    delete(@start[tid]);
  }'

# Save as a script
cat > /opt/trace-scripts/write_latency.bt << "EOF"
#!/usr/bin/env bpftrace
tracepoint:syscalls:sys_enter_write { @start[tid] = nsecs; }
tracepoint:syscalls:sys_exit_write  /@start[tid]/ {
  @latency_us = hist((nsecs - @start[tid]) / 1000);
  delete(@start[tid]);
}
EOF
sudo bpftrace /opt/trace-scripts/write_latency.bt
```

---

## BCC — Python Frontend

Best for: feature-rich tools, custom reporting, integration with Python.

```python
#!/usr/bin/env python3
# trace_opens.py — trace open() calls using BCC
from bcc import BPF

prog = r"""
#include <uapi/linux/ptrace.h>
#include <linux/sched.h>

BPF_HASH(counts, u32, u64);

TRACEPOINT_PROBE(syscalls, sys_enter_openat) {
    u32 pid = bpf_get_current_pid_tgid() >> 32;
    u64 zero = 0, *val;
    val = counts.lookup_or_init(&pid, &zero);
    (*val)++;
    return 0;
}
"""

b = BPF(text=prog)
import time, os

while True:
    time.sleep(2)
    print(f"{'PID':>8}  {'OPENS':>8}  {'COMM'}")
    for k, v in sorted(b["counts"].items(), key=lambda x: -x[1].value)[:10]:
        try:
            comm = open(f"/proc/{k.value}/comm").read().strip()
        except:
            comm = "?"
        print(f"{k.value:>8}  {v.value:>8}  {comm}")
    b["counts"].clear()
```

```bash
sudo python3 trace_opens.py
```

---

## libbpf C — Portable Core eBPF

Best for: production-grade tools, CO-RE (Compile Once, Run Everywhere).

### BPF program (`tracer.bpf.c`)

```c
// SPDX-License-Identifier: GPL-2.0
#include <vmlinux.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>
#include <bpf/bpf_core_read.h>

struct event {
    u32 pid;
    u32 uid;
    char comm[16];
    char filename[256];
};

struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 256 * 1024);
} events SEC(".maps");

SEC("tracepoint/syscalls/sys_enter_openat")
int trace_openat(struct trace_event_raw_sys_enter *ctx)
{
    struct event *e;
    e = bpf_ringbuf_reserve(&events, sizeof(*e), 0);
    if (!e) return 0;

    e->pid = bpf_get_current_pid_tgid() >> 32;
    e->uid = bpf_get_current_uid_gid();
    bpf_get_current_comm(&e->comm, sizeof(e->comm));
    bpf_probe_read_user_str(e->filename, sizeof(e->filename),
                            (const char *)ctx->args[1]);
    bpf_ringbuf_submit(e, 0);
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
```

### Compile

```bash
# Generate vmlinux.h (kernel type definitions)
bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h

# Compile
clang -O2 -g -target bpf \
  -D__TARGET_ARCH_x86 \
  -I/usr/include/$(uname -m)-linux-gnu \
  -c tracer.bpf.c -o tracer.bpf.o

# Verify
bpftool prog dump xlated file tracer.bpf.o
```

---

## Go + cilium/ebpf — Production eBPF in Go

Best for: long-running daemons, Kubernetes integrations, modern eBPF agents.

```go
// main.go
package main

import (
    "log"
    "os"
    "os/signal"
    "syscall"

    "github.com/cilium/ebpf"
    "github.com/cilium/ebpf/link"
    "github.com/cilium/ebpf/ringbuf"
    "github.com/cilium/ebpf/rlimit"
)

//go:generate go run github.com/cilium/ebpf/cmd/bpf2go -cc clang Tracer tracer.bpf.c

func main() {
    if err := rlimit.RemoveMemlock(); err != nil {
        log.Fatal(err)
    }

    objs := TracerObjects{}
    if err := LoadTracerObjects(&objs, nil); err != nil {
        log.Fatalf("loading BPF objects: %v", err)
    }
    defer objs.Close()

    tp, err := link.Tracepoint("syscalls", "sys_enter_openat", objs.TraceOpenat, nil)
    if err != nil {
        log.Fatalf("tracepoint: %v", err)
    }
    defer tp.Close()

    rd, err := ringbuf.NewReader(objs.Events)
    if err != nil {
        log.Fatalf("ringbuf: %v", err)
    }
    defer rd.Close()

    log.Println("Tracing openat() calls. Ctrl+C to stop.")

    sig := make(chan os.Signal, 1)
    signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)

    go func() {
        for {
            rec, err := rd.Read()
            if err != nil {
                return
            }
            log.Printf("event: %s", rec.RawSample)
        }
    }()

    <-sig
}
```

```bash
# Generate Go bindings from BPF C
go generate ./...

# Build
go build -o tracer .
sudo ./tracer
```

---

## Rust + Aya — Type-safe eBPF

Best for: modern eBPF programs with Rust's memory safety guarantees.

```bash
# Create new Aya project
cargo install aya-cli
aya new my-tracer
cd my-tracer

# Project structure:
#   my-tracer/          — user-space Rust code
#   my-tracer-ebpf/     — kernel-space eBPF Rust code

# Build and run
cargo xtask run
```

---

## Useful Resources

- [Brendan Gregg's BPF Performance Tools](https://www.brendangregg.com/bpf-performance-tools-book.html)
- [bpftrace Reference Guide](https://github.com/iovisor/bpftrace/blob/master/docs/reference_guide.md)
- [cilium/ebpf Go docs](https://pkg.go.dev/github.com/cilium/ebpf)
- [Aya Book](https://aya-rs.dev/book/)
- [Linux BPF docs](https://www.kernel.org/doc/html/latest/bpf/)
- [BPF map types reference](https://elixir.bootlin.com/linux/latest/source/include/uapi/linux/bpf.h)
