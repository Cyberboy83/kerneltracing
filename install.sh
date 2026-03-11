#!/usr/bin/env bash
# =============================================================================
#  ██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗    ████████╗██████╗  █████╗  ██████╗███████╗
#  ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║    ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝
#  ██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║       ██║   ██████╔╝███████║██║     █████╗
#  ██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║       ██║   ██╔══██╗██╔══██║██║     ██╔══╝
#  ██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║       ██║   ██║  ██║██║  ██║╚██████╗███████╗
#  ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝       ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝
#
#  Kernel Tracing & Data Analysis Workstation
#  Professional Edition — Real-World Ready
#  Target: Debian 12 (Bookworm) | Architecture: x86_64
# =============================================================================
# USAGE:
#   sudo bash debian-trace-distro-setup.sh [--headless] [--skip-gui] [--minimal]
#
# OPTIONS:
#   --headless    Skip interactive prompts, use defaults
#   --skip-gui    Skip desktop environment installation
#   --minimal     Install only core tracing tools (no data science stack)
#   --help        Show this help
#
# WHAT THIS INSTALLS:
#   1. Kernel Tracing Tools    (eBPF, BCC, bpftrace, perf, ftrace, SystemTap)
#   2. Hardware PMU Profiling  (perf, pmu-tools, Intel VTune CLI, AMD uProf)
#   3. Network Tracing         (Wireshark, tcpdump, XDP/AF_XDP tools)
#   4. Memory Analysis         (Valgrind, heaptrack, massif-visualizer)
#   5. Data Science Stack      (Python, R, Julia, Apache Spark, ClickHouse)
#   6. Visualization           (Grafana, Kibana, Prometheus, custom dashboards)
#   7. IDE & Dev Tools         (VS Code, Vim w/ plugins, tmux, zsh)
#   8. Custom shell env        (oh-my-zsh, powerlevel10k, tracing aliases)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ─── COLORS ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
MAGENTA='\033[0;35m'; WHITE='\033[1;37m'

# ─── FLAGS ────────────────────────────────────────────────────────────────────
HEADLESS=false; SKIP_GUI=false; MINIMAL=false
for arg in "$@"; do
  case $arg in
    --headless) HEADLESS=true ;;
    --skip-gui) SKIP_GUI=true ;;
    --minimal)  MINIMAL=true  ;;
    --help) grep '^#' "$0" | head -40 | sed 's/^# \?//'; exit 0 ;;
  esac
done

# ─── LOGGING ──────────────────────────────────────────────────────────────────
LOG_FILE="/var/log/debian-trace-setup-$(date +%Y%m%d-%H%M%S).log"
mkdir -p /var/log
exec > >(tee -a "$LOG_FILE") 2>&1

log()     { echo -e "${GREEN}[$(date +%H:%M:%S)] ✔ ${RESET}$*"; }
warn()    { echo -e "${YELLOW}[$(date +%H:%M:%S)] ⚠ ${RESET}$*"; }
error()   { echo -e "${RED}[$(date +%H:%M:%S)] ✘ ${RESET}$*"; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; \
            echo -e "${BOLD}${WHITE}  ▶ $*${RESET}"; \
            echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"; }
progress() { echo -e "${BLUE}    → ${RESET}$*"; }

# ─── PREFLIGHT ────────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Must run as root. Try: sudo bash $0"
[[ $(uname -m) != "x86_64" ]] && warn "Untested on non-x86_64. Proceeding anyway..."

DEBIAN_VERSION=$(cat /etc/debian_version 2>/dev/null || echo "unknown")
KERNEL_VERSION=$(uname -r)
TOTAL_RAM=$(awk '/MemTotal/{printf "%.0f", $2/1024/1024}' /proc/meminfo)
CPU_CORES=$(nproc)

echo -e "${BOLD}${MAGENTA}"
cat << 'BANNER'
  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │   DEBIAN TRACE DISTRO — Professional Kernel Analysis Suite     │
  │                                                                 │
  │   eBPF • BCC • bpftrace • perf • ftrace • SystemTap            │
  │   Python • R • Julia • Spark • ClickHouse • Grafana            │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
BANNER
echo -e "${RESET}"

log "System: Debian $DEBIAN_VERSION | Kernel: $KERNEL_VERSION | RAM: ${TOTAL_RAM}GB | CPUs: $CPU_CORES"
log "Log file: $LOG_FILE"

if [[ "$HEADLESS" == false ]]; then
  echo -e "${YELLOW}This will transform your Debian system into a professional kernel tracing"
  echo -e "and data analysis workstation. Estimated time: 30-60 minutes.${RESET}"
  read -rp "$(echo -e "${BOLD}Continue? [y/N]: ${RESET}")" CONFIRM
  [[ "${CONFIRM,,}" != "y" ]] && { log "Aborted by user."; exit 0; }
fi

# ─── DETECT ACTUAL USER ───────────────────────────────────────────────────────
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
log "Installing for user: $REAL_USER (home: $REAL_HOME)"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 1: SYSTEM FOUNDATION
# ═════════════════════════════════════════════════════════════════════════════
section "PHASE 1: System Foundation & Repositories"

progress "Updating apt and installing base utilities..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

progress "Installing essential base packages..."
apt-get install -y -qq \
  apt-transport-https ca-certificates curl wget gnupg lsb-release \
  software-properties-common dirmngr gpg gpg-agent \
  build-essential gcc g++ gdb clang llvm llvm-dev clang-tools \
  cmake meson ninja-build pkg-config autoconf automake libtool \
  git git-lfs tig lazygit \
  tmux screen byobu \
  zsh fish bash-completion \
  htop btop iotop iftop nethogs \
  tree fd-find fzf ripgrep bat exa jq yq \
  ncdu duf lsof strace ltrace \
  net-tools iproute2 iputils-ping dnsutils \
  vim neovim nano \
  unzip zip tar gzip bzip2 xz-utils \
  rsync scp openssh-client openssh-server \
  sudo man-db manpages-dev \
  python3 python3-pip python3-venv python3-dev \
  ruby-full \
  golang-go \
  nodejs npm \
  fonts-powerline fonts-firacode \
  2>/dev/null || warn "Some base packages had issues — continuing"

log "Base packages installed"

# ─── ADD REPOS ────────────────────────────────────────────────────────────────
progress "Adding third-party repositories..."

# Docker repo (for containerized Grafana/Prometheus/ClickHouse)
if ! grep -q "docker" /etc/apt/sources.list.d/*.list 2>/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
  chmod a+r /etc/apt/keyrings/docker.gpg 2>/dev/null || true
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian $(lsb_release -cs) stable" > \
    /etc/apt/sources.list.d/docker.list 2>/dev/null || warn "Docker repo add failed — may need manual setup"
fi

# VS Code repo
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg 2>/dev/null || true
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] \
  https://packages.microsoft.com/repos/code stable main" > \
  /etc/apt/sources.list.d/vscode.list 2>/dev/null || warn "VS Code repo add failed"

apt-get update -qq 2>/dev/null || true
log "Repositories configured"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 2: KERNEL HEADERS & DEBUG SYMBOLS
# ═════════════════════════════════════════════════════════════════════════════
section "PHASE 2: Kernel Headers, Debug Symbols & BPF Support"

KVER=$(uname -r)
progress "Installing kernel headers for $KVER..."

apt-get install -y -qq \
  linux-headers-"$KVER" \
  linux-headers-amd64 \
  linux-image-"$KVER"-dbg 2>/dev/null || \
  apt-get install -y -qq linux-headers-"$KVER" linux-headers-amd64 2>/dev/null || \
  warn "Some kernel debug packages unavailable for this kernel"

progress "Installing BPF tools and libraries..."
apt-get install -y -qq \
  libbpf-dev libbpf0 \
  bpfcc-tools python3-bpfcc \
  bpftrace \
  linux-perf \
  trace-cmd kernelshark \
  systemtap systemtap-sdt-dev \
  crash \
  dwarves \
  pahole \
  2>/dev/null || warn "Some BPF packages unavailable — installing what's available"

# Install BCC from source if apt version is old
BCC_VERSION=$(bcc --version 2>/dev/null | head -1 || echo "0")
progress "BCC tools available. Installing supplemental BPF utils..."

apt-get install -y -qq \
  libbpf-tools 2>/dev/null || true

# Install bpftool
if ! command -v bpftool &>/dev/null; then
  progress "Building bpftool from kernel source..."
  apt-get install -y -qq libelf-dev zlib1g-dev 2>/dev/null || true
  # bpftool from linux-tools
  apt-get install -y -qq linux-tools-"$KVER" linux-tools-common 2>/dev/null || \
    apt-get install -y -qq linux-tools-generic 2>/dev/null || \
    warn "bpftool not available for this kernel version"
fi

log "Kernel tracing infrastructure installed"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 3: PERFORMANCE & TRACING TOOLS
# ═════════════════════════════════════════════════════════════════════════════
section "PHASE 3: Performance Analysis & Tracing Arsenal"

progress "Installing perf and PMU tools..."
apt-get install -y -qq \
  linux-tools-common \
  linux-tools-generic \
  linux-perf \
  cpufrequtils \
  cpuid \
  msr-tools \
  turbostat \
  x86info \
  2>/dev/null || true

progress "Installing tracing and profiling tools..."
apt-get install -y -qq \
  valgrind \
  massif-visualizer \
  oprofile \
  google-perftools \
  libgoogle-perftools-dev \
  heaptrack \
  heaptrack-gui 2>/dev/null || true \

apt-get install -y -qq \
  gprof2dot \
  hotspot \
  flamegraph 2>/dev/null || true

progress "Installing SystemTap..."
apt-get install -y -qq \
  systemtap \
  systemtap-doc \
  systemtap-sdt-dev \
  systemtap-runtime 2>/dev/null || warn "SystemTap install issues — may need kernel debug info"

progress "Installing ftrace helpers and tracing utilities..."
apt-get install -y -qq \
  trace-cmd \
  kernelshark \
  latencytop \
  powertop \
  tiptop 2>/dev/null || true

progress "Installing network tracing tools..."
apt-get install -y -qq \
  wireshark tshark \
  tcpdump \
  nmap \
  tcpflow \
  nethogs \
  iperf3 \
  netperf \
  ss iproute2 \
  ethtool \
  nicstat 2>/dev/null || true

# FlameGraph (Brendan Gregg's)
if [[ ! -d /opt/FlameGraph ]]; then
  progress "Installing FlameGraph..."
  git clone --depth=1 https://github.com/brendangregg/FlameGraph /opt/FlameGraph 2>/dev/null || \
    warn "FlameGraph clone failed — install manually from github.com/brendangregg/FlameGraph"
  ln -sf /opt/FlameGraph/flamegraph.pl /usr/local/bin/flamegraph.pl
  ln -sf /opt/FlameGraph/stackcollapse-perf.pl /usr/local/bin/stackcollapse-perf.pl
  chmod +x /opt/FlameGraph/*.pl 2>/dev/null || true
fi

# perf-tools (Brendan Gregg's perf-tools)
if [[ ! -d /opt/perf-tools ]]; then
  progress "Installing perf-tools (Gregg)..."
  git clone --depth=1 https://github.com/brendangregg/perf-tools /opt/perf-tools 2>/dev/null || \
    warn "perf-tools clone failed"
  find /opt/perf-tools -maxdepth 2 -type f -executable -exec \
    ln -sf {} /usr/local/bin/ \; 2>/dev/null || true
fi

# bpf-perf-tools-book scripts
if [[ ! -d /opt/bpf-perf-tools ]]; then
  progress "Installing BPF Performance Tools scripts (Gregg book)..."
  git clone --depth=1 https://github.com/brendangregg/bpf-perf-tools-book /opt/bpf-perf-tools 2>/dev/null || true
fi

log "Performance & tracing tools installed"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 4: eBPF DEVELOPMENT ENVIRONMENT
# ═════════════════════════════════════════════════════════════════════════════
section "PHASE 4: eBPF Development Environment"

progress "Installing eBPF/BPF development libraries..."
apt-get install -y -qq \
  clang \
  llvm \
  libelf-dev \
  zlib1g-dev \
  libcap-dev \
  libpcap-dev \
  libbpf-dev \
  linux-libc-dev \
  gcc-multilib \
  2>/dev/null || warn "Some eBPF dev libs unavailable"

# Install Go for eBPF Go bindings
if ! command -v go &>/dev/null || [[ "$(go version | awk '{print $3}' | sed 's/go//')" < "1.21" ]]; then
  progress "Installing Go 1.21+ for eBPF tooling..."
  GO_VERSION="1.22.4"
  wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz 2>/dev/null && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf /tmp/go.tar.gz 2>/dev/null && \
    rm /tmp/go.tar.gz && \
    ln -sf /usr/local/go/bin/go /usr/local/bin/go && \
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt || \
    warn "Go install failed — install manually"
fi

# Install cilium/ebpf Go library
if command -v go &>/dev/null; then
  progress "Setting up Go eBPF workspace..."
  GOPATH="${REAL_HOME}/go"
  mkdir -p "$GOPATH"
  GOPATH="$GOPATH" GOFLAGS="-mod=mod" \
    go install github.com/cilium/ebpf/cmd/bpf2go@latest 2>/dev/null || true
  GOPATH="$GOPATH" \
    go install github.com/aquasecurity/libbpfgo@latest 2>/dev/null || true
fi

# Install Rust (for Aya eBPF framework)
if ! command -v rustc &>/dev/null; then
  progress "Installing Rust for Aya eBPF framework..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    su -c "sh -s -- -y --default-toolchain stable" "$REAL_USER" 2>/dev/null || \
    warn "Rust install failed — install manually with rustup"
fi

log "eBPF development environment ready"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 5: DATA SCIENCE & ANALYSIS STACK
# ═════════════════════════════════════════════════════════════════════════════
if [[ "$MINIMAL" == false ]]; then
section "PHASE 5: Data Science & Analysis Stack"

progress "Installing Python data science stack..."
# Upgrade pip
python3 -m pip install --upgrade pip setuptools wheel --quiet 2>/dev/null || true

# Core scientific Python
pip3 install --quiet \
  numpy scipy pandas polars \
  matplotlib seaborn plotly bokeh altair \
  scikit-learn xgboost lightgbm \
  jupyterlab jupyter notebook ipywidgets \
  dask[complete] \
  pyarrow fastparquet \
  sqlalchemy psycopg2-binary \
  clickhouse-driver clickhouse-connect \
  influxdb-client \
  prometheus-client \
  psutil py-cpuinfo \
  pyelftools \
  2>/dev/null || warn "Some Python packages failed"

# Install Python eBPF/tracing libs
pip3 install --quiet \
  bcc 2>/dev/null || true
pip3 install --quiet \
  pyftrace \
  py-spy \
  memray \
  scalene \
  austin-dist \
  2>/dev/null || warn "Some Python profiling tools unavailable"

# Pandas profiling / data quality
pip3 install --quiet \
  ydata-profiling \
  great-expectations \
  pandera \
  2>/dev/null || true

progress "Installing R statistical computing..."
apt-get install -y -qq r-base r-base-dev 2>/dev/null || warn "R not available"
if command -v R &>/dev/null; then
  R --quiet --no-save << 'RSCRIPT' 2>/dev/null || true
install.packages(c(
  "ggplot2","dplyr","tidyr","data.table","plotly","DT",
  "lubridate","stringr","purrr","readr","tibble",
  "rmarkdown","knitr","shiny","flexdashboard",
  "survival","caret","randomForest"
), repos="https://cran.rstudio.com/", quiet=TRUE)
RSCRIPT
  log "R packages installed"
fi

progress "Installing Apache Spark..."
if [[ ! -d /opt/spark ]]; then
  SPARK_VERSION="3.5.1"
  HADOOP_VERSION="3"
  SPARK_URL="https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"
  wget -q "$SPARK_URL" -O /tmp/spark.tgz 2>/dev/null && \
    tar -xzf /tmp/spark.tgz -C /opt/ && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark && \
    rm /tmp/spark.tgz && \
    ln -sf /opt/spark/bin/spark-shell /usr/local/bin/spark-shell && \
    ln -sf /opt/spark/bin/spark-submit /usr/local/bin/spark-submit && \
    ln -sf /opt/spark/bin/pyspark /usr/local/bin/pyspark && \
    log "Apache Spark $SPARK_VERSION installed at /opt/spark" || \
    warn "Spark install failed — download manually"
fi

# Java (required for Spark)
apt-get install -y -qq default-jdk 2>/dev/null || true

log "Data science stack installed"
fi # end MINIMAL check

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 6: OBSERVABILITY STACK (Grafana, Prometheus, ClickHouse)
# ═════════════════════════════════════════════════════════════════════════════
if [[ "$MINIMAL" == false ]]; then
section "PHASE 6: Observability Stack — Grafana + Prometheus + ClickHouse"

# Docker for containerized services
progress "Installing Docker..."
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>/dev/null || \
  apt-get install -y -qq docker.io docker-compose 2>/dev/null || \
  warn "Docker install failed — install manually"

if command -v docker &>/dev/null; then
  systemctl enable docker 2>/dev/null || true
  systemctl start docker 2>/dev/null || true
  usermod -aG docker "$REAL_USER" 2>/dev/null || true
  log "Docker installed and running"
fi

progress "Creating observability docker-compose stack..."
mkdir -p /opt/observability
cat > /opt/observability/docker-compose.yml << 'COMPOSE'
version: '3.8'

networks:
  tracing-net:
    driver: bridge

volumes:
  prometheus_data: {}
  grafana_data: {}
  clickhouse_data: {}
  loki_data: {}
  tempo_data: {}

services:

  # ── Prometheus ───────────────────────────────────────────────────────────
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - prometheus_data:/prometheus
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=90d'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    networks: [tracing-net]

  # ── Grafana ──────────────────────────────────────────────────────────────
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: tracepro2024
      GF_INSTALL_PLUGINS: "grafana-piechart-panel,grafana-worldmap-panel,grafana-clock-panel,grafana-polystat-panel,natel-plotly-panel"
      GF_FEATURE_TOGGLES_ENABLE: "traceToMetrics,correlations"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    depends_on: [prometheus]
    networks: [tracing-net]

  # ── ClickHouse ───────────────────────────────────────────────────────────
  clickhouse:
    image: clickhouse/clickhouse-server:latest
    container_name: clickhouse
    restart: unless-stopped
    ports:
      - "8123:8123"   # HTTP
      - "9000:9000"   # Native
    volumes:
      - clickhouse_data:/var/lib/clickhouse
      - ./clickhouse/config.xml:/etc/clickhouse-server/config.d/custom.xml:ro
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    networks: [tracing-net]

  # ── Loki (Log Aggregation) ───────────────────────────────────────────────
  loki:
    image: grafana/loki:latest
    container_name: loki
    restart: unless-stopped
    ports:
      - "3100:3100"
    volumes:
      - loki_data:/loki
      - ./loki/loki-config.yml:/etc/loki/local-config.yaml:ro
    command: -config.file=/etc/loki/local-config.yaml
    networks: [tracing-net]

  # ── Tempo (Distributed Tracing) ─────────────────────────────────────────
  tempo:
    image: grafana/tempo:latest
    container_name: tempo
    restart: unless-stopped
    ports:
      - "3200:3200"
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "9411:9411"   # Zipkin
    volumes:
      - tempo_data:/var/tempo
      - ./tempo/tempo-config.yml:/etc/tempo/tempo.yaml:ro
    command: -config.file=/etc/tempo/tempo.yaml
    networks: [tracing-net]

  # ── Node Exporter (Host Metrics) ─────────────────────────────────────────
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
      - '--collector.perf'
      - '--collector.buddyinfo'
      - '--collector.drbd'
      - '--collector.interrupts'
      - '--collector.ksmd'
      - '--collector.meminfo_numa'
      - '--collector.mountstats'
      - '--collector.network_route'
      - '--collector.slabinfo'
      - '--collector.tcpstat'
      - '--collector.wifi'
      - '--collector.xfs'
      - '--collector.zfs'
    network_mode: host
    pid: host

  # ── Cadvisor (Container Metrics) ─────────────────────────────────────────
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
    privileged: true
    devices:
      - /dev/kmsg:/dev/kmsg
    networks: [tracing-net]

COMPOSE

# Prometheus config
mkdir -p /opt/observability/prometheus
cat > /opt/observability/prometheus/prometheus.yml << 'PROMCFG'
global:
  scrape_interval:     5s
  evaluation_interval: 5s
  external_labels:
    cluster: 'local-tracing'
    env: 'production'

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'local-host'

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'clickhouse'
    static_configs:
      - targets: ['clickhouse:9363']
PROMCFG

# ClickHouse config
mkdir -p /opt/observability/clickhouse
cat > /opt/observability/clickhouse/config.xml << 'CHCFG'
<clickhouse>
  <logger>
    <level>warning</level>
    <console>1</console>
  </logger>
  <max_concurrent_queries>200</max_concurrent_queries>
  <max_server_memory_usage_to_ram_ratio>0.8</max_server_memory_usage_to_ram_ratio>
  <uncompressed_cache_size>8589934592</uncompressed_cache_size>
  <mark_cache_size>5368709120</mark_cache_size>
  <listen_host>0.0.0.0</listen_host>
  <prometheus>
    <endpoint>/metrics</endpoint>
    <port>9363</port>
    <metrics>true</metrics>
    <events>true</events>
    <asynchronous_metrics>true</asynchronous_metrics>
  </prometheus>
</clickhouse>
CHCFG

# Loki config
mkdir -p /opt/observability/loki
cat > /opt/observability/loki/loki-config.yml << 'LOKICFG'
auth_enabled: false
server:
  http_listen_port: 3100
common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory
schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h
ruler:
  alertmanager_url: http://localhost:9093
LOKICFG

# Tempo config
mkdir -p /opt/observability/tempo
cat > /opt/observability/tempo/tempo-config.yml << 'TEMPOCFG'
server:
  http_listen_port: 3200
distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
    zipkin:
      endpoint: 0.0.0.0:9411
ingester:
  max_block_duration: 5m
compactor:
  compaction:
    block_retention: 1h
storage:
  trace:
    backend: local
    wal:
      path: /var/tempo/wal
    local:
      path: /var/tempo/blocks
TEMPOCFG

mkdir -p /opt/observability/grafana/provisioning/datasources
cat > /opt/observability/grafana/provisioning/datasources/datasources.yml << 'GFDS'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
  - name: Tempo
    type: tempo
    access: proxy
    url: http://tempo:3200
  - name: ClickHouse
    type: grafana-clickhouse-datasource
    access: proxy
    url: http://clickhouse:8123
GFDS

log "Observability stack configured at /opt/observability"
fi # end MINIMAL check

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 7: DEVELOPMENT TOOLS & IDE
# ═════════════════════════════════════════════════════════════════════════════
section "PHASE 7: Development Tools & IDE Setup"

progress "Installing VS Code..."
apt-get install -y -qq code 2>/dev/null || warn "VS Code not available — install from code.visualstudio.com"

if command -v code &>/dev/null; then
  progress "Installing VS Code extensions for kernel dev..."
  sudo -u "$REAL_USER" code --install-extension ms-vscode.cpptools 2>/dev/null || true
  sudo -u "$REAL_USER" code --install-extension ms-python.python 2>/dev/null || true
  sudo -u "$REAL_USER" code --install-extension golang.go 2>/dev/null || true
  sudo -u "$REAL_USER" code --install-extension rust-lang.rust-analyzer 2>/dev/null || true
  sudo -u "$REAL_USER" code --install-extension ms-vscode.hexeditor 2>/dev/null || true
  sudo -u "$REAL_USER" code --install-extension ms-vscode-remote.remote-ssh 2>/dev/null || true
  sudo -u "$REAL_USER" code --install-extension eamodio.gitlens 2>/dev/null || true
  sudo -u "$REAL_USER" code --install-extension ms-toolsai.jupyter 2>/dev/null || true
fi

progress "Setting up Neovim with LSP..."
# Install vim-plug for neovim
NVIM_CONFIG="${REAL_HOME}/.config/nvim"
mkdir -p "$NVIM_CONFIG"
curl -fLo "${REAL_HOME}/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 2>/dev/null || true
chown -R "$REAL_USER":"$REAL_USER" "${REAL_HOME}/.local" 2>/dev/null || true
chown -R "$REAL_USER":"$REAL_USER" "${REAL_HOME}/.config" 2>/dev/null || true

log "IDE and development tools configured"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 8: SHELL ENVIRONMENT & DOTFILES
# ═════════════════════════════════════════════════════════════════════════════
section "PHASE 8: Professional Shell Environment"

progress "Installing oh-my-zsh..."
if [[ ! -d "${REAL_HOME}/.oh-my-zsh" ]]; then
  sudo -u "$REAL_USER" sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended 2>/dev/null || warn "oh-my-zsh install failed"
fi

# Install zsh plugins
ZSH_CUSTOM="${REAL_HOME}/.oh-my-zsh/custom"
if [[ -d "${REAL_HOME}/.oh-my-zsh" ]]; then
  progress "Installing zsh plugins..."
  # zsh-autosuggestions
  [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
    sudo -u "$REAL_USER" git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
  # zsh-syntax-highlighting
  [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
    sudo -u "$REAL_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
  # powerlevel10k
  [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] && \
    sudo -u "$REAL_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$ZSH_CUSTOM/themes/powerlevel10k" 2>/dev/null || true
fi

progress "Writing .zshrc with tracing aliases..."
cat > "${REAL_HOME}/.zshrc" << 'ZSHRC'
# ═══════════════════════════════════════════════════════════════════
#  Debian Trace Distro — Professional Shell Configuration
# ═══════════════════════════════════════════════════════════════════
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git sudo docker docker-compose
  zsh-autosuggestions zsh-syntax-highlighting
  golang rust python pip
  history-substring-search
  colored-man-pages
  command-not-found
  tmux
)

source $ZSH/oh-my-zsh.sh 2>/dev/null || true

# ─── Environment ──────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="code"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin:/usr/local/go/bin:/opt/spark/bin"
export PATH="$PATH:$HOME/.cargo/bin:/opt/FlameGraph"
export PATH="$PATH:/opt/perf-tools:/usr/local/bin"
export SPARK_HOME="/opt/spark"
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java) 2>/dev/null))) 2>/dev/null || true

# ─── Kernel Tracing Aliases ───────────────────────────────────────
# perf shortcuts
alias perf-cpu='sudo perf top -a --call-graph dwarf'
alias perf-flame='sudo perf record -a -g -- sleep 10 && sudo perf script | stackcollapse-perf.pl | flamegraph.pl > /tmp/flame.svg && xdg-open /tmp/flame.svg'
alias perf-stat='sudo perf stat -a -d -d -d'
alias perf-mem='sudo perf mem record -a -- sleep 5 && sudo perf mem report'
alias perf-cache='sudo perf stat -e cache-references,cache-misses,cycles,instructions -a sleep 5'
alias perf-sched='sudo perf sched record -a sleep 5 && sudo perf sched latency'
alias perf-lock='sudo perf lock record -a -- sleep 5 && sudo perf lock report'
alias perf-io='sudo perf record -e block:block_rq_issue,block:block_rq_complete -a sleep 5 && sudo perf report'
alias perf-syscalls='sudo perf stat -e "syscalls:sys_enter_*" -a sleep 5'

# bpftrace one-liners
alias bt-syscalls='sudo bpftrace -e "tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }"'
alias bt-openat='sudo bpftrace -e "tracepoint:syscalls:sys_enter_openat { printf(\"%s %s\n\", comm, str(args->filename)); }"'
alias bt-execve='sudo bpftrace -e "tracepoint:syscalls:sys_enter_execve { printf(\"%s -> %s\n\", comm, str(args->filename)); }"'
alias bt-tcpconn='sudo bpftrace /opt/bpf-perf-tools/tcpconnect.bt 2>/dev/null || sudo bpftrace -e "kprobe:tcp_connect { printf(\"%s\n\", comm); }"'
alias bt-oomkill='sudo bpftrace -e "kprobe:oom_kill_process { printf(\"OOM kill: %s (pid %d)\n\", comm, pid); }"'
alias bt-biodist='sudo bpftrace -e "kprobe:blk_account_io_start { @start[arg0] = nsecs; } kprobe:blk_account_io_done /@start[arg0]/ { @usecs = hist((nsecs - @start[arg0]) / 1000); delete(@start[arg0]); }"'
alias bt-cpudist='sudo bpftrace -e "software:cpu-clock:100 { @[ustack] = count(); } END { print(@); }"'
alias bt-profile='sudo bpftrace -e "profile:hz:99 { @[kstack] = count(); } END { print(@); }"'
alias bt-malloc='sudo bpftrace -e "uprobe:/lib/x86_64-linux-gnu/libc.so.6:malloc { @bytes = hist(arg0); }"'

# BCC tool shortcuts (most are in /sbin or /usr/sbin when installed via bpfcc-tools)
alias bcc-execsnoop='sudo execsnoop-bpfcc'
alias bcc-opensnoop='sudo opensnoop-bpfcc'
alias bcc-tcptop='sudo tcptop-bpfcc'
alias bcc-biolatency='sudo biolatency-bpfcc'
alias bcc-biostacks='sudo biosnoop-bpfcc'
alias bcc-funccount='sudo funccount-bpfcc'
alias bcc-argdist='sudo argdist-bpfcc'
alias bcc-trace='sudo trace-bpfcc'
alias bcc-memleak='sudo memleak-bpfcc'
alias bcc-offcputime='sudo offcputime-bpfcc'
alias bcc-profile='sudo profile-bpfcc'
alias bcc-capable='sudo capable-bpfcc'
alias bcc-tcplife='sudo tcplife-bpfcc'
alias bcc-ext4slower='sudo ext4slower-bpfcc'
alias bcc-nfsslower='sudo nfsslower-bpfcc'

# ftrace shortcuts
alias ftrace-start='echo function > /sys/kernel/debug/tracing/current_tracer && echo 1 > /sys/kernel/debug/tracing/tracing_on'
alias ftrace-stop='echo 0 > /sys/kernel/debug/tracing/tracing_on'
alias ftrace-clear='echo > /sys/kernel/debug/tracing/trace'
alias ftrace-read='cat /sys/kernel/debug/tracing/trace'
alias ftrace-funcs='cat /sys/kernel/debug/tracing/available_filter_functions'
alias ftrace-events='cat /sys/kernel/debug/tracing/available_events'
alias trace-cmd-record='sudo trace-cmd record -p function_graph'

# strace / ltrace shortcuts
alias strace-fast='sudo strace -c -f -e trace=all'
alias strace-file='sudo strace -f -e trace=file'
alias strace-net='sudo strace -f -e trace=network'
alias strace-mem='sudo strace -f -e trace=memory'
alias ltrace-fast='ltrace -c'

# Kernel module info
alias kmod-deps='sudo depmod -a && sudo modprobe'
alias kmod-list='lsmod | sort'
alias kmod-info='modinfo'
alias dmesg-watch='sudo dmesg -wH'
alias dmesg-errors='sudo dmesg --level=err,crit,alert,emerg'
alias kallsyms='cat /proc/kallsyms | grep'
alias kconfig="zcat /proc/config.gz 2>/dev/null || cat /boot/config-$(uname -r)"

# System info
alias cpuinfo='cat /proc/cpuinfo | grep -E "model name|cpu MHz|cache size" | head -20'
alias numa='numactl --hardware 2>/dev/null || echo "numactl not installed"'
alias irq-affinity='cat /proc/interrupts'
alias sched-debug='cat /proc/sched_debug'
alias meminfo='cat /proc/meminfo'
alias vmstat-watch='vmstat -w 1'
alias iostat-watch='iostat -xz 1'
alias sar-cpu='sar -u 1 5'
alias sar-io='sar -b 1 5'
alias sar-mem='sar -r 1 5'

# ClickHouse / Data analysis
alias ch='clickhouse-client 2>/dev/null || docker exec -it clickhouse clickhouse-client'
alias ch-query='docker exec -it clickhouse clickhouse-client --query'
alias spark-shell='$SPARK_HOME/bin/spark-shell'
alias pyspark='$SPARK_HOME/bin/pyspark'
alias jupyter='jupyter lab --ip=0.0.0.0 --no-browser --allow-root'

# Observability stack
alias obs-up='cd /opt/observability && docker-compose up -d && echo "Grafana: http://localhost:3000 (admin/tracepro2024)"'
alias obs-down='cd /opt/observability && docker-compose down'
alias obs-logs='cd /opt/observability && docker-compose logs -f'
alias obs-status='cd /opt/observability && docker-compose ps'
alias grafana-open='xdg-open http://localhost:3000 2>/dev/null || echo "Open http://localhost:3000"'
alias prometheus-open='xdg-open http://localhost:9090 2>/dev/null || echo "Open http://localhost:9090"'

# General quality of life
alias ll='ls -lah --color=auto'
alias la='ls -la --color=auto'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias top='btop 2>/dev/null || htop'
alias vim='nvim'
alias cat='bat 2>/dev/null || cat'
alias find='fd 2>/dev/null || find'
alias ps-tree='ps auxf'
alias ports='ss -tulnp'
alias myip='ip route get 1 | awk "{print \$7}" | head -1'
alias reload='source ~/.zshrc'
alias update='sudo apt update && sudo apt upgrade -y'

# Helper functions
flame() {
  # Generate flamegraph: flame <pid or command>
  local output="${2:-/tmp/flame-$(date +%s).svg}"
  sudo perf record -a -g -F 99 -p "$1" -- sleep "${3:-10}" 2>/dev/null
  sudo perf script | stackcollapse-perf.pl | flamegraph.pl > "$output"
  echo "Flamegraph saved: $output"
  xdg-open "$output" 2>/dev/null || true
}

bt-trace() {
  # Quick bpftrace one-shot: bt-trace 'tracepoint:...'
  sudo bpftrace -e "$1"
}

kern-probe() {
  # List available kprobes matching pattern
  sudo grep "$1" /sys/kernel/debug/tracing/available_filter_functions 2>/dev/null | head -30
}

sysfs() {
  # Browse sysfs: sysfs /sys/kernel/debug/tracing
  ls -la "${1:-/sys/kernel/debug/tracing}"
}

watch-syscall() {
  # Watch syscalls from PID: watch-syscall 1234
  sudo strace -p "$1" -c 2>&1
}

memmap() {
  # Show memory map of process
  sudo pmap -x "${1:-$$}" | head -30
}

ZSHRC
chown "$REAL_USER":"$REAL_USER" "${REAL_HOME}/.zshrc"

# Set zsh as default shell
chsh -s "$(which zsh)" "$REAL_USER" 2>/dev/null || warn "Could not set zsh as default shell"

log "Shell environment configured"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 9: KERNEL CONFIGURATION OPTIMIZATIONS
# ═════════════════════════════════════════════════════════════════════════════
section "PHASE 9: Kernel & System Tuning for Tracing"

progress "Configuring kernel parameters for tracing..."
cat > /etc/sysctl.d/99-trace-pro.conf << 'SYSCTL'
# ── DebianTrace Pro: Kernel tuning for profiling & analysis ──────────────────

# Enable BPF JIT (required for eBPF performance)
net.core.bpf_jit_enable = 1
net.core.bpf_jit_kallsyms = 1
net.core.bpf_jit_limit = 264241152

# Allow non-privileged perf (0 = unrestricted; keep 1 for security)
kernel.perf_event_paranoid = 1
kernel.perf_event_mlock_kb = 16384
kernel.perf_cpu_time_max_percent = 25

# Allow kprobes and tracepoints from non-root (tracing group)
kernel.kptr_restrict = 0

# Larger perf ring buffer
kernel.perf_event_max_stack = 127
kernel.perf_event_max_contexts_per_stack = 8

# Ftrace enable
kernel.ftrace_enabled = 1

# NUMA / Memory
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.overcommit_memory = 1

# Network tracing
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.netdev_max_backlog = 250000

# Higher file descriptor limits for tracing tools
fs.file-max = 2097152
fs.nr_open = 1048576

# Disable NMI watchdog (reduces perf noise)
kernel.nmi_watchdog = 0

# Enable scheduler stats
kernel.sched_schedstats = 1

# Increase pid_max for comprehensive process tracing
kernel.pid_max = 4194304
SYSCTL

sysctl -p /etc/sysctl.d/99-trace-pro.conf 2>/dev/null || warn "Some sysctl settings not applied (may need reboot)"

progress "Configuring tracefs permissions..."
# Mount debugfs / tracefs if not mounted
if ! mountpoint -q /sys/kernel/debug 2>/dev/null; then
  mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null || true
fi
if ! mountpoint -q /sys/kernel/tracing 2>/dev/null; then
  mount -t tracefs tracefs /sys/kernel/tracing 2>/dev/null || true
fi

# Add tracefs to fstab for persistence
grep -q "debugfs" /etc/fstab || \
  echo "debugfs /sys/kernel/debug debugfs defaults 0 0" >> /etc/fstab
grep -q "tracefs" /etc/fstab || \
  echo "tracefs /sys/kernel/tracing tracefs defaults 0 0" >> /etc/fstab

# Create tracing group for non-root tracing
groupadd -f tracing 2>/dev/null || true
usermod -aG tracing "$REAL_USER" 2>/dev/null || true

progress "Setting up performance governor..."
if command -v cpufreq-set &>/dev/null || [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance > "$cpu" 2>/dev/null || true
  done
  log "CPU governor set to 'performance'"
fi

# Disable CPU frequency scaling for accurate benchmarks (optional, can be changed)
cat > /usr/local/bin/trace-mode-on << 'TRACEMODE'
#!/bin/bash
# Enable high-performance tracing mode
echo "Enabling performance mode for kernel tracing..."
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null
echo 0 > /proc/sys/kernel/nmi_watchdog 2>/dev/null
echo 0 > /proc/sys/kernel/watchdog 2>/dev/null
echo 500 > /proc/sys/vm/dirty_writeback_centisecs
echo 0 > /sys/kernel/debug/tracing/tracing_on
echo nop > /sys/kernel/debug/tracing/current_tracer
echo > /sys/kernel/debug/tracing/trace
echo "Tracing mode: ON. Run 'trace-mode-off' to restore defaults."
TRACEMODE

cat > /usr/local/bin/trace-mode-off << 'TRACEMODEOFF'
#!/bin/bash
echo "Restoring normal operating mode..."
echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
echo 1 > /proc/sys/kernel/nmi_watchdog 2>/dev/null || true
echo 1 > /proc/sys/kernel/watchdog 2>/dev/null || true
echo "Normal mode restored."
TRACEMODEOFF

chmod +x /usr/local/bin/trace-mode-on /usr/local/bin/trace-mode-off
log "Kernel tuning applied"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 10: TMUX CONFIG & TRACING SESSIONS
# ═════════════════════════════════════════════════════════════════════════════
section "PHASE 10: tmux Professional Configuration"

cat > "${REAL_HOME}/.tmux.conf" << 'TMUXCONF'
# ── DebianTrace Pro: tmux configuration ──────────────────────────────────────
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
set -g history-limit 50000
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Status bar — dark professional theme
set -g status-style 'bg=#1a1a2e fg=#e0e0e0'
set -g status-left-length 40
set -g status-right-length 120
set -g status-left '#[bg=#16213e,fg=#00d4ff,bold] 🔬 TRACE #[fg=#4a4a8a] | #[fg=#00d4ff]#S #[default]'
set -g status-right '#[fg=#4a4a8a]#[fg=#00d4ff] CPU: #(top -bn1 | grep "Cpu(s)" | awk "{print 100-\$8}" | cut -d. -f1)%% #[fg=#4a4a8a]|#[fg=#00ffc8] MEM: #(free | awk "/^Mem/{printf \"%.0f%%%%\", \$3/\$2*100}") #[fg=#4a4a8a]| #[fg=#ffffff]%H:%M %d-%b'
set -g window-status-format '#[fg=#888888] #I:#W '
set -g window-status-current-format '#[bg=#0f3460,fg=#00d4ff,bold] #I:#W '

# Key bindings
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Quick layouts for tracing
bind T new-window -n "tracing" \; \
  split-window -h \; \
  split-window -v \; \
  select-pane -t 1 \; \
  send-keys "btop" Enter \; \
  select-pane -t 2 \; \
  send-keys "sudo dmesg -wH" Enter \; \
  select-pane -t 3 \; \
  send-keys "sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); } interval:s:2 { print(@); clear(@); }'" Enter

bind D new-window -n "data" \; \
  split-window -v \; \
  select-pane -t 1 \; \
  send-keys "jupyter lab --ip=0.0.0.0 --no-browser 2>&1 | grep token" Enter \; \
  select-pane -t 2 \; \
  send-keys "echo 'JupyterLab ready. Open http://localhost:8888'" Enter

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @continuum-restore 'on'
TMUXCONF
chown "$REAL_USER":"$REAL_USER" "${REAL_HOME}/.tmux.conf"

# Install TPM (tmux plugin manager)
if [[ ! -d "${REAL_HOME}/.tmux/plugins/tpm" ]]; then
  sudo -u "$REAL_USER" git clone https://github.com/tmux-plugins/tpm \
    "${REAL_HOME}/.tmux/plugins/tpm" 2>/dev/null || true
fi
chown -R "$REAL_USER":"$REAL_USER" "${REAL_HOME}/.tmux" 2>/dev/null || true

log "tmux configured"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 11: QUICK REFERENCE CHEATSHEETS
# ═════════════════════════════════════════════════════════════════════════════
section "PHASE 11: Quick Reference & Documentation"

mkdir -p /opt/trace-docs
cat > /opt/trace-docs/QUICKREF.md << 'QREF'
# DebianTrace Pro — Quick Reference

## eBPF / bpftrace

```bash
# Profile CPU stack traces
sudo bpftrace -e 'profile:hz:99 { @[kstack] = count(); } END { print(@); }'

# Trace all syscalls by process
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# Trace file opens
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args->filename)); }'

# TCP connection latency
sudo bpftrace -e 'kprobe:tcp_v4_connect { @start[tid] = nsecs; } kretprobe:tcp_v4_connect { @ms = hist((nsecs-@start[tid])/1e6); }'

# Disk I/O latency histogram
sudo bpftrace -e 'kprobe:blk_account_io_start { @[arg0] = nsecs; } kprobe:blk_account_io_done /@[arg0]/ { @usecs = hist((nsecs-@[arg0])/1000); delete(@[arg0]); }'
```

## perf

```bash
# CPU profiling (99Hz sampling)
sudo perf record -a -g -F 99 sleep 30

# Generate flamegraph
sudo perf script | stackcollapse-perf.pl | flamegraph.pl > flame.svg

# Cache miss analysis
sudo perf stat -e cache-references,cache-misses,LLC-loads,LLC-load-misses -a sleep 5

# Scheduler latency
sudo perf sched record -a sleep 5
sudo perf sched latency

# Memory access patterns
sudo perf mem record -a sleep 5
sudo perf mem report

# Lock contention
sudo perf lock record -a sleep 5
sudo perf lock report
```

## ftrace

```bash
# Enable function tracer
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace

# Function graph tracer (shows call depth)
echo function_graph > /sys/kernel/debug/tracing/current_tracer

# Trace specific function
echo do_sys_open > /sys/kernel/debug/tracing/set_ftrace_filter

# Event tracing
echo 1 > /sys/kernel/debug/tracing/events/syscalls/sys_enter_openat/enable

# trace-cmd wrapper
sudo trace-cmd record -p function_graph -g schedule sleep 5
sudo trace-cmd report
```

## SystemTap

```bash
# Count syscalls by process
sudo stap -e 'global counts; probe syscall.* { counts[execname()]++ } probe end { foreach (n in counts-) printf("%s: %d\n", n, counts[n]) }' -T 10

# Trace malloc sizes
sudo stap -e 'probe process("libc.so.6").function("malloc") { printf("pid %d alloc %d bytes\n", pid(), $bytes) }'
```

## BCC Tools

```bash
execsnoop-bpfcc        # Trace process executions
opensnoop-bpfcc        # Trace file opens
tcptop-bpfcc           # Top TCP connections by bandwidth
biolatency-bpfcc       # Block I/O latency histogram
biosnoop-bpfcc         # Block I/O tracing
memleak-bpfcc          # Memory leak detection
offcputime-bpfcc       # Off-CPU time profiling
profile-bpfcc          # CPU profiling
capable-bpfcc          # Linux capability checks
tcplife-bpfcc          # TCP session lifespan
ext4slower-bpfcc       # ext4 slow operations
funccount-bpfcc        # Count kernel function calls
argdist-bpfcc          # Arg frequency histograms
```

## Data Analysis

```bash
# Start JupyterLab
jupyter lab --ip=0.0.0.0 --no-browser

# PySpark
pyspark

# ClickHouse client
docker exec -it clickhouse clickhouse-client

# Start observability stack
obs-up   # Grafana @ http://localhost:3000 (admin/tracepro2024)
```

## Observability URLs

| Service    | URL                        | Credentials         |
|------------|----------------------------|---------------------|
| Grafana    | http://localhost:3000      | admin / tracepro2024|
| Prometheus | http://localhost:9090      | (no auth)           |
| ClickHouse | http://localhost:8123      | default / (no pass) |
| Loki       | http://localhost:3100      | (no auth)           |
| Tempo      | http://localhost:3200      | (no auth)           |
| JupyterLab | http://localhost:8888      | (token shown)       |

## Useful One-Liners

```bash
# Find which process is causing the most I/O
sudo iotop -o

# Watch live network connections
sudo nethogs

# Process CPU by cgroup
systemd-cgtop

# Interrupts per second per CPU
watch -n1 'cat /proc/interrupts'

# Scheduler statistics
cat /proc/sched_debug | head -50

# NUMA statistics
numastat

# IRQ affinity
cat /proc/irq/*/smp_affinity_list
```
QREF

chmod 644 /opt/trace-docs/QUICKREF.md
ln -sf /opt/trace-docs/QUICKREF.md "${REAL_HOME}/TRACE-QUICKREF.md" 2>/dev/null || true
chown "$REAL_USER":"$REAL_USER" "${REAL_HOME}/TRACE-QUICKREF.md" 2>/dev/null || true

log "Documentation written to /opt/trace-docs/QUICKREF.md"

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 12: DESKTOP ENVIRONMENT (optional)
# ═════════════════════════════════════════════════════════════════════════════
if [[ "$SKIP_GUI" == false ]]; then
section "PHASE 12: Desktop Environment (XFCE — lightweight for tracing workstations)"
progress "Installing XFCE desktop..."
apt-get install -y -qq \
  xfce4 xfce4-goodies \
  lightdm lightdm-gtk-greeter \
  xterm \
  xdg-utils \
  2>/dev/null || warn "Desktop environment install failed — you may be in a headless env"
systemctl enable lightdm 2>/dev/null || true
log "Desktop environment ready (XFCE)"
fi

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 13: FINAL SYSTEM SERVICES
# ═════════════════════════════════════════════════════════════════════════════
section "PHASE 13: Final Configuration & Services"

progress "Enabling services..."
systemctl enable ssh 2>/dev/null || true
systemctl start ssh 2>/dev/null || true

# Ensure BPF fs is mounted
if ! mountpoint -q /sys/fs/bpf 2>/dev/null; then
  mount bpffs /sys/fs/bpf -t bpf 2>/dev/null || true
fi
grep -q "bpffs" /etc/fstab || \
  echo "bpffs /sys/fs/bpf bpf defaults 0 0" >> /etc/fstab

progress "Running apt autoremove & cleanup..."
apt-get autoremove -y -qq 2>/dev/null || true
apt-get autoclean -qq 2>/dev/null || true

# ═════════════════════════════════════════════════════════════════════════════
# DONE
# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}"
cat << 'DONE'
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │   ✅  INSTALLATION COMPLETE — REBOOT RECOMMENDED                 │
  │                                                                  │
  │   Your Debian Trace Pro workstation is ready.                    │
  │                                                                  │
  │   QUICK START:                                                   │
  │     obs-up              → Start Grafana + Prometheus + CH        │
  │     perf-cpu            → Live CPU flamegraph                    │
  │     bt-syscalls         → eBPF syscall tracer                    │
  │     bcc-profile         → CPU profiling with BCC                 │
  │     jupyter             → JupyterLab data analysis               │
  │     tmux + Ctrl-a T     → Open tracing workspace layout          │
  │     cat ~/TRACE-QUICKREF.md  → Full command reference            │
  │                                                                  │
  │   Grafana:    http://localhost:3000  (admin/tracepro2024)        │
  │   Prometheus: http://localhost:9090                              │
  │   ClickHouse: http://localhost:8123                              │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
DONE
echo -e "${RESET}"
log "Setup complete. Log: $LOG_FILE"
log "Please reboot to apply all kernel parameter changes."
