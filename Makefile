# ══════════════════════════════════════════════════════════════════
#  DebianTrace Pro — Makefile
#  Convenience targets for development and deployment
# ══════════════════════════════════════════════════════════════════

.PHONY: help install install-minimal install-server lint test obs-up obs-down obs-status clean

# Default target
help:
	@echo ""
	@echo "  DebianTrace Pro — Available targets"
	@echo ""
	@echo "  Installation:"
	@echo "    make install           Full interactive install"
	@echo "    make install-minimal   Core tracing tools only"
	@echo "    make install-server    Headless, no GUI"
	@echo ""
	@echo "  Development:"
	@echo "    make lint              Run shellcheck on all scripts"
	@echo "    make test              Run bats test suite (if installed)"
	@echo ""
	@echo "  Observability:"
	@echo "    make obs-up            Start Grafana + Prometheus + ClickHouse stack"
	@echo "    make obs-down          Stop observability stack"
	@echo "    make obs-status        Show container status"
	@echo ""
	@echo "    make clean             Remove generated logs and temp files"
	@echo ""

# ── Installation ──────────────────────────────────────────────────
install:
	@sudo bash install.sh

install-minimal:
	@sudo bash install.sh --minimal --headless

install-server:
	@sudo bash install.sh --headless --skip-gui

# ── Linting ───────────────────────────────────────────────────────
lint:
	@echo "Running shellcheck..."
	@shellcheck -S warning install.sh
	@find scripts/ -name "*.sh" -exec shellcheck -S warning {} \;
	@echo "All checks passed."

# ── Tests ─────────────────────────────────────────────────────────
test:
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/; \
	else \
		echo "bats not installed. Run: sudo apt install bats"; \
	fi

# ── Observability ─────────────────────────────────────────────────
obs-up:
	@cd observability && docker compose up -d
	@echo "Grafana: http://localhost:3000 (admin / tracepro2024)"

obs-down:
	@cd observability && docker compose down

obs-status:
	@cd observability && docker compose ps

# ── Cleanup ───────────────────────────────────────────────────────
clean:
	@rm -f /var/log/debian-trace-setup-*.log 2>/dev/null || true
	@echo "Cleaned up log files."
