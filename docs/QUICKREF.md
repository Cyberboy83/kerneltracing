# DebianTrace Pro — Quick Reference

## bpftrace One-Liners

```bash
# CPU profiling by kernel stack (99Hz)
sudo bpftrace -e 'profile:hz:99 { @[kstack] = count(); } END { print(@); }'

# Count syscalls by process
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# Trace file opens (openat)
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args->filename)); }'

# Disk I/O latency histogram (µs)
sudo bpftrace -e '
  kprobe:blk_account_io_start  { @start[arg0] = nsecs; }
  kprobe:blk_account_io_done  /@start[arg0]/ {
    @usecs = hist((nsecs - @start[arg0]) / 1000);
    delete(@start[arg0]);
  }'

# TCP connect latency
sudo bpftrace -e '
  kprobe:tcp_v4_connect          { @start[tid] = nsecs; }
  kretprobe:tcp_v4_connect       { @ms = hist((nsecs - @start[tid]) / 1e6); }'

# malloc size distribution (libc uprobe)
sudo bpftrace -e 'uprobe:/lib/x86_64-linux-gnu/libc.so.6:malloc { @bytes = hist(arg0); }'

# OOM kill watcher
sudo bpftrace -e 'kprobe:oom_kill_process { printf("OOM: %s pid=%d\n", comm, pid); }'

# Trace process executions
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%s -> %s\n", comm, str(args->filename)); }'

# Network packet drops
sudo bpftrace -e 'tracepoint:skb:kfree_skb { @[kstack] = count(); }'
```

## perf

```bash
# Live CPU top with call graphs
sudo perf top -a --call-graph dwarf

# 10-second CPU flamegraph
sudo perf record -a -g -F 99 -- sleep 10
sudo perf script | stackcollapse-perf.pl | flamegraph.pl > flame.svg

# Cache miss analysis
sudo perf stat -e cache-references,cache-misses,LLC-loads,LLC-load-misses -a sleep 5

# Detailed CPU counters (3-level)
sudo perf stat -a -d -d -d -- sleep 5

# Scheduler wake-up latency
sudo perf sched record -a sleep 5
sudo perf sched latency

# Lock contention
sudo perf lock record -a -- sleep 5
sudo perf lock report

# Memory access analysis
sudo perf mem record -a sleep 5
sudo perf mem report

# Block I/O events
sudo perf record -e block:block_rq_issue,block:block_rq_complete -a sleep 5
sudo perf report

# Syscall counts
sudo perf stat -e 'syscalls:sys_enter_*' -a sleep 5
```

## ftrace

```bash
# Enable function tracer
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace
echo 0 > /sys/kernel/debug/tracing/tracing_on

# Function graph tracer (shows nesting depth + duration)
echo function_graph > /sys/kernel/debug/tracing/current_tracer
echo do_sys_open > /sys/kernel/debug/tracing/set_graph_function

# Enable tracepoint events
echo 1 > /sys/kernel/debug/tracing/events/syscalls/sys_enter_openat/enable
cat /sys/kernel/debug/tracing/trace_pipe

# trace-cmd wrapper (recommended)
sudo trace-cmd record -p function_graph -g schedule sleep 5
sudo trace-cmd report
kernelshark   # GUI

# List available events
cat /sys/kernel/debug/tracing/available_events | grep tcp
```

## BCC Tools

```bash
execsnoop-bpfcc             # Trace new process executions
opensnoop-bpfcc             # Trace file opens
biolatency-bpfcc            # Block I/O latency histogram
biosnoop-bpfcc              # Block I/O per-request tracing
tcptop-bpfcc                # Top TCP senders/receivers
tcplife-bpfcc               # TCP session lifespan + bytes
memleak-bpfcc               # Memory leak detection (heap)
offcputime-bpfcc            # Off-CPU time flame data
profile-bpfcc               # CPU profiler (user+kernel stacks)
capable-bpfcc               # CAP_* capability usage trace
ext4slower-bpfcc 10         # ext4 ops slower than 10ms
nfsslower-bpfcc             # NFS slow operations
funccount-bpfcc 'tcp_*'     # Count function calls matching pattern
argdist-bpfcc -H 'p::do_sys_open():int:$retval'  # Return value histogram
trace-bpfcc 'p::do_sys_open "%s", arg1'          # Printf-style tracing
```

## SystemTap

```bash
# Count syscalls by process for 10 seconds
sudo stap -e '
  global counts
  probe syscall.* { counts[execname()]++ }
  probe end { foreach (n in counts-) printf("%s: %d\n", n, counts[n]) }
' -T 10

# Trace malloc > 1MB
sudo stap -e '
  probe process("libc.so.6").function("malloc") {
    if ($bytes > 1048576) printf("pid %d alloc %d bytes\n", pid(), $bytes)
  }'

# Kernel function entry/return with args
sudo stap -e '
  probe kernel.function("tcp_sendmsg") {
    printf("pid=%d len=%d\n", pid(), $size)
  }'
```

## Valgrind / Memory

```bash
# Memory error detection
valgrind --leak-check=full --show-leak-kinds=all ./myapp

# Heap profiling
valgrind --tool=massif --pages-as-heap=yes ./myapp
ms_print massif.out.* | head -50

# Cache simulation
valgrind --tool=cachegrind ./myapp
cg_annotate cachegrind.out.*

# Call graph profiling
valgrind --tool=callgrind ./myapp
callgrind_annotate callgrind.out.*

# Heaptrack (faster alternative)
heaptrack ./myapp
heaptrack_gui heaptrack.myapp.*.gz
```

## Network Tracing

```bash
# Packet capture
sudo tcpdump -i any -nn -w /tmp/capture.pcap 'tcp port 80'
tshark -r /tmp/capture.pcap -T fields -e ip.src -e ip.dst -e tcp.dstport

# Live Wireshark (requires X/Wayland)
sudo wireshark &

# TCP connections by bandwidth
sudo tcptop-bpfcc

# Network I/O by process
sudo nethogs

# Connection state summary
ss -s

# All established connections
ss -tnp state established

# Interface statistics
ethtool -S eth0 | grep -v " 0$"
```

## ClickHouse — Kernel Event Analytics

```bash
# Connect
docker exec -it clickhouse clickhouse-client

# Create a trace events table
CREATE TABLE trace_events (
    ts       DateTime64(9),
    cpu      UInt8,
    pid      UInt32,
    comm     String,
    event    String,
    latency_us Float64
) ENGINE = MergeTree()
ORDER BY (ts, event, pid);

# Ingest from bpftrace JSON output
# (use bpftrace -f json and pipe to clickhouse-client)

# Query: p99 latency per event type
SELECT event,
       quantile(0.99)(latency_us) AS p99_us,
       count() AS cnt
FROM trace_events
GROUP BY event ORDER BY p99_us DESC;
```

## Observability Stack

```bash
obs-up       # docker compose up -d (all services)
obs-down     # docker compose down
obs-status   # docker compose ps
obs-logs     # docker compose logs -f

# Service URLs
# Grafana:    http://localhost:3000  (admin / tracepro2024)
# Prometheus: http://localhost:9090
# ClickHouse: http://localhost:8123
# Loki:       http://localhost:3100
# Tempo:      http://localhost:3200
```

## System Diagnostics

```bash
# Live kernel log
sudo dmesg -wH

# Kernel errors only
sudo dmesg --level=err,crit,alert,emerg

# Scheduler debug dump
cat /proc/sched_debug | head -80

# NUMA topology
numactl --hardware

# Interrupt distribution per CPU
cat /proc/interrupts | column -t | head -30

# IRQ affinity
for irq in /proc/irq/*/smp_affinity_list; do
  printf "IRQ %s: %s\n" "$(basename $(dirname $irq))" "$(cat $irq)"
done

# CPU frequency per core
grep MHz /proc/cpuinfo

# Memory pressure
cat /proc/vmstat | grep -E 'pgfault|pgmajfault|pswpin|pswpout'

# Open file descriptors (system-wide)
cat /proc/sys/fs/file-nr

# TCP socket statistics
ss -s
cat /proc/net/sockstat
```
