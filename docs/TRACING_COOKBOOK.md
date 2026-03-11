# DebianTrace Pro — Tracing Cookbook

Real-world recipes for common kernel tracing and performance analysis scenarios.

---

## Recipe 1: Diagnosing High CPU Usage

**Symptom:** A process or the system is consuming unexpected CPU.

```bash
# Step 1 — Identify which process/function is hot
sudo perf top -a --call-graph dwarf

# Step 2 — Capture 30s flamegraph for the offending PID
sudo flame <PID> /tmp/cpu-flame.svg 30

# Step 3 — Profile kernel stacks specifically
sudo bpftrace -e 'profile:hz:99 { @[kstack] = count(); } END { print(@); }'

# Step 4 — Check if it's a specific syscall
sudo perf stat -e 'syscalls:sys_enter_*' -p <PID> sleep 5

# Step 5 — Off-CPU time (ruling out blocking)
sudo offcputime-bpfcc -p <PID> 5
```

---

## Recipe 2: Diagnosing High Disk I/O Latency

**Symptom:** Application is slow; `iostat` shows high await times.

```bash
# Step 1 — I/O latency histogram (all block devices)
sudo biolatency-bpfcc -D 5

# Step 2 — Who is doing the I/O?
sudo biosnoop-bpfcc

# Step 3 — Latency distribution in microseconds via bpftrace
sudo bpftrace -e '
  kprobe:blk_account_io_start  { @start[arg0] = nsecs; }
  kprobe:blk_account_io_done  /@start[arg0]/ {
    @usecs = hist((nsecs - @start[arg0]) / 1000);
    delete(@start[arg0]);
  }'

# Step 4 — ext4-specific slow ops
sudo ext4slower-bpfcc 10    # ops slower than 10ms

# Step 5 — Check I/O scheduler queue depth
cat /sys/block/sda/queue/nr_requests
iostat -xz 1
```

---

## Recipe 3: Memory Leak Detection

**Symptom:** A process grows in memory over time without being freed.

```bash
# Step 1 — Kernel-level alloc tracking (bpftrace)
sudo memleak-bpfcc -p <PID> --top 10 5

# Step 2 — Valgrind full leak check
valgrind --leak-check=full --show-leak-kinds=all \
  --track-origins=yes \
  --log-file=/tmp/valgrind.log \
  ./myapp

# Step 3 — Heaptrack (lower overhead, production-friendly)
heaptrack ./myapp
heaptrack_gui heaptrack.myapp.*.gz

# Step 4 — malloc call stack distribution
sudo bpftrace -e '
  uprobe:/lib/x86_64-linux-gnu/libc.so.6:malloc {
    @bytes[ustack] = sum(arg0);
  }
  END { print(@bytes); }'

# Step 5 — Python-specific (memray)
python3 -m memray run myapp.py
python3 -m memray flamegraph memray-myapp-*.bin
```

---

## Recipe 4: Network Latency Investigation

**Symptom:** TCP connections have unexpectedly high latency.

```bash
# Step 1 — TCP connection latency
sudo bpftrace -e '
  kprobe:tcp_v4_connect       { @start[tid] = nsecs; }
  kretprobe:tcp_v4_connect    { @ms = hist((nsecs - @start[tid]) / 1e6); }'

# Step 2 — TCP session summary (lifespan + bytes)
sudo tcplife-bpfcc

# Step 3 — Socket send/receive latency
sudo tcptop-bpfcc

# Step 4 — Packet retransmits
sudo bpftrace -e 'kprobe:tcp_retransmit_skb { @[comm, pid] = count(); }'

# Step 5 — Packet captures for deep analysis
sudo tcpdump -i any -nn -w /tmp/trace.pcap 'host 10.0.0.1'
tshark -r /tmp/trace.pcap -q -z io,stat,1

# Step 6 — Check interrupt affinity (ensure NIC IRQs are spread across CPUs)
cat /proc/interrupts | grep eth
```

---

## Recipe 5: Scheduler Latency Analysis

**Symptom:** Latency-sensitive app has occasional spikes.

```bash
# Step 1 — Record scheduler events
sudo perf sched record -a sleep 10
sudo perf sched latency | head -30

# Step 2 — Find worst wake-up latencies
sudo perf sched timehist | sort -k7 -rn | head -20

# Step 3 — Trace wakeup-to-run delay with bpftrace
sudo bpftrace -e '
  tracepoint:sched:sched_wakeup  { @ts[args->pid] = nsecs; }
  tracepoint:sched:sched_switch  {
    if (@ts[args->next_pid]) {
      @delay_us = hist((nsecs - @ts[args->next_pid]) / 1000);
      delete(@ts[args->next_pid]);
    }
  }'

# Step 4 — Check scheduler statistics
cat /proc/sched_debug | head -60

# Step 5 — Identify priority inversions / throttled cgroups
cat /sys/fs/cgroup/cpu/docker/*/cpu.stat 2>/dev/null | grep throttled
```

---

## Recipe 6: Kernel Function Tracing (ftrace)

**Use case:** Trace the call path of a specific kernel function.

```bash
# Step 1 — Enable function_graph tracer
echo function_graph > /sys/kernel/debug/tracing/current_tracer
echo do_sys_open > /sys/kernel/debug/tracing/set_graph_function
echo 1 > /sys/kernel/debug/tracing/tracing_on
sleep 2
echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace | head -100

# Step 2 — Filter by PID
echo <PID> > /sys/kernel/debug/tracing/set_ftrace_pid

# Step 3 — Use trace-cmd for easier workflow
sudo trace-cmd record -p function_graph \
  -g do_sys_open \
  -g tcp_sendmsg \
  sleep 3
sudo trace-cmd report | head -200
kernelshark    # GUI visualization

# Step 4 — Measure function latency
sudo bpftrace -e '
  kprobe:do_sys_open          { @start[tid] = nsecs; }
  kretprobe:do_sys_open       { @us = hist((nsecs - @start[tid]) / 1000); }'
```

---

## Recipe 7: Container / cgroup Tracing

**Use case:** Trace activity inside a specific Docker container.

```bash
# Get container PID namespace
CONTAINER_ID="mycontainer"
CPID=$(docker inspect --format '{{.State.Pid}}' $CONTAINER_ID)

# Trace only processes in that cgroup
sudo bpftrace -e "
  tracepoint:syscalls:sys_enter_openat
  /cgroup == cgroupid(\"/sys/fs/cgroup/system.slice/docker-$(docker inspect --format '{{.Id}}' $CONTAINER_ID).scope\")/
  { printf(\"%s %s\n\", comm, str(args->filename)); }"

# OR: trace by PID namespace
sudo bpftrace -e "
  tracepoint:raw_syscalls:sys_enter
  /nsid[\"pid\"] == $CPID/ { @[comm] = count(); }"

# Profile container CPU
sudo perf record -a -g -F 99 --cgroup docker/$CONTAINER_ID sleep 10
sudo perf script | stackcollapse-perf.pl | flamegraph.pl > container.svg
```

---

## Recipe 8: eBPF Program Development

**Use case:** Write a custom eBPF tracing program in C.

```c
// my_tracer.bpf.c
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __type(key, u32);
    __type(value, u64);
    __uint(max_entries, 1024);
} latency_map SEC(".maps");

SEC("kprobe/do_sys_openat2")
int trace_open_entry(struct pt_regs *ctx) {
    u32 pid = bpf_get_current_pid_tgid() >> 32;
    u64 ts  = bpf_ktime_get_ns();
    bpf_map_update_elem(&latency_map, &pid, &ts, BPF_ANY);
    return 0;
}

char LICENSE[] SEC("license") = "GPL";
```

```bash
# Compile with clang
clang -O2 -target bpf -D__TARGET_ARCH_x86 \
  -I/usr/include/$(uname -m)-linux-gnu \
  -c my_tracer.bpf.c -o my_tracer.bpf.o

# Load with bpftool
sudo bpftool prog load my_tracer.bpf.o /sys/fs/bpf/my_tracer

# Or use Go with cilium/ebpf — see docs/EBPF_GUIDE.md
```

---

## Recipe 9: Ingest Trace Data into ClickHouse

**Use case:** Store bpftrace output for long-term analysis in ClickHouse.

```bash
# Step 1 — Create table
docker exec -it clickhouse clickhouse-client --query "
CREATE TABLE IF NOT EXISTS syscall_events (
    ts       DateTime64(9)  DEFAULT now64(),
    comm     String,
    pid      UInt32,
    syscall  String,
    latency_us Float64
) ENGINE = MergeTree()
PARTITION BY toDate(ts)
ORDER BY (ts, comm)
TTL ts + INTERVAL 30 DAY;"

# Step 2 — Stream bpftrace JSON output into ClickHouse
sudo bpftrace -f json -e '
  tracepoint:raw_syscalls:sys_enter {
    printf("{\"comm\":\"%s\",\"pid\":%d,\"syscall\":\"%d\"}\n", comm, pid, args->id);
  }' | \
  docker exec -i clickhouse clickhouse-client \
    --query "INSERT INTO syscall_events (comm, pid, syscall) FORMAT JSONEachRow"

# Step 3 — Query
docker exec -it clickhouse clickhouse-client --query "
SELECT comm, count() as calls, avg(latency_us) as avg_us
FROM syscall_events
WHERE ts > now() - INTERVAL 5 MINUTE
GROUP BY comm ORDER BY calls DESC LIMIT 20;"
```
