#!/usr/bin/env bats
# ══════════════════════════════════════════════════════════════════
#  DebianTrace Pro — Basic test suite
#  Run: bats tests/install.bats
#  Install bats: sudo apt install bats
# ══════════════════════════════════════════════════════════════════

# ── Script existence & permissions ────────────────────────────────

@test "install.sh exists" {
  [ -f "install.sh" ]
}

@test "install.sh is executable" {
  [ -x "install.sh" ]
}

@test "scripts/trace-mode-on.sh exists and is executable" {
  [ -x "scripts/trace-mode-on.sh" ]
}

@test "scripts/trace-mode-off.sh exists and is executable" {
  [ -x "scripts/trace-mode-off.sh" ]
}

@test "scripts/flame.sh exists and is executable" {
  [ -x "scripts/flame.sh" ]
}

@test "scripts/uninstall.sh exists and is executable" {
  [ -x "scripts/uninstall.sh" ]
}

# ── Bash syntax checks ────────────────────────────────────────────

@test "install.sh has valid bash syntax" {
  bash -n install.sh
}

@test "scripts/trace-mode-on.sh has valid bash syntax" {
  bash -n scripts/trace-mode-on.sh
}

@test "scripts/trace-mode-off.sh has valid bash syntax" {
  bash -n scripts/trace-mode-off.sh
}

@test "scripts/flame.sh has valid bash syntax" {
  bash -n scripts/flame.sh
}

@test "scripts/uninstall.sh has valid bash syntax" {
  bash -n scripts/uninstall.sh
}

# ── Config files exist ────────────────────────────────────────────

@test "configs/zsh/.zshrc exists" {
  [ -f "configs/zsh/.zshrc" ]
}

@test "configs/tmux/.tmux.conf exists" {
  [ -f "configs/tmux/.tmux.conf" ]
}

@test "configs/sysctl/99-trace-pro.conf exists" {
  [ -f "configs/sysctl/99-trace-pro.conf" ]
}

# ── Observability configs exist ───────────────────────────────────

@test "observability/docker-compose.yml exists" {
  [ -f "observability/docker-compose.yml" ]
}

@test "observability/prometheus/prometheus.yml exists" {
  [ -f "observability/prometheus/prometheus.yml" ]
}

@test "observability/clickhouse/config.xml exists" {
  [ -f "observability/clickhouse/config.xml" ]
}

@test "observability/loki/loki-config.yml exists" {
  [ -f "observability/loki/loki-config.yml" ]
}

@test "observability/tempo/tempo-config.yml exists" {
  [ -f "observability/tempo/tempo-config.yml" ]
}

@test "observability/grafana/provisioning/datasources/datasources.yml exists" {
  [ -f "observability/grafana/provisioning/datasources/datasources.yml" ]
}

# ── Documentation exists ──────────────────────────────────────────

@test "docs/QUICKREF.md exists" {
  [ -f "docs/QUICKREF.md" ]
}

@test "docs/TRACING_COOKBOOK.md exists" {
  [ -f "docs/TRACING_COOKBOOK.md" ]
}

@test "docs/EBPF_GUIDE.md exists" {
  [ -f "docs/EBPF_GUIDE.md" ]
}

# ── install.sh flags ─────────────────────────────────────────────

@test "install.sh --help exits cleanly" {
  run bash install.sh --help
  [ "$status" -eq 0 ]
}

@test "install.sh contains set -euo pipefail" {
  grep -q "set -euo pipefail" install.sh
}

@test "install.sh contains all 13 phase markers" {
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13; do
    grep -q "PHASE $i" install.sh
  done
}

# ── YAML validity ─────────────────────────────────────────────────

@test "docker-compose.yml is valid YAML (python3)" {
  python3 -c "import yaml; yaml.safe_load(open('observability/docker-compose.yml'))"
}

@test "prometheus.yml is valid YAML (python3)" {
  python3 -c "import yaml; yaml.safe_load(open('observability/prometheus/prometheus.yml'))"
}

@test "datasources.yml is valid YAML (python3)" {
  python3 -c "import yaml; yaml.safe_load(open('observability/grafana/provisioning/datasources/datasources.yml'))"
}
