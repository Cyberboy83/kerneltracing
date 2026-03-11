# Contributing to DebianTrace Pro

Thank you for your interest in contributing! This document covers how to get started.

---

## Ways to Contribute

- **Bug reports** — Open an issue with the bug report template
- **Feature requests** — Open an issue with the feature request template
- **Code** — Fix bugs, add tools, improve configs
- **Docs** — Improve the cookbook, cheatsheet, or README
- **Testing** — Verify on different Debian versions or hardware

---

## Development Setup

```bash
git clone https://github.com/youruser/debian-trace-pro.git
cd debian-trace-pro

# Install shellcheck for linting
sudo apt install shellcheck

# Lint all shell scripts
shellcheck install.sh scripts/*.sh
```

---

## Pull Request Guidelines

1. **Fork** the repo and create a branch: `git checkout -b feat/my-feature`
2. **Keep changes focused** — one PR per feature or fix
3. **Lint your shell scripts** — all scripts must pass `shellcheck` with zero errors
4. **Test on Debian 12** — confirm your changes work on a clean Debian 12 install (VM is fine)
5. **Update docs** — if you add a tool or alias, update `docs/QUICKREF.md`
6. **Update CHANGELOG.md** under `[Unreleased]`
7. **Open a PR** against `main` with a clear description

---

## Shell Script Standards

- Use `set -euo pipefail` at the top of all scripts
- Quote all variables: `"$VAR"` not `$VAR`
- Use `2>/dev/null || true` for non-critical commands that might fail
- Log with the provided `log()`, `warn()`, `error()`, `section()` helpers
- Do not hardcode paths — use variables or command substitution

---

## Adding a New Tool

1. Add the `apt-get install` line to the appropriate phase in `install.sh`
2. Add a shell alias or function to `configs/zsh/.zshrc`
3. Document it in `docs/QUICKREF.md`
4. Add a card to `docs/dashboard.html` if it's a significant tool

---

## Adding Observability Components

Edit `observability/docker-compose.yml` and the relevant config file under `observability/`.  
Make sure any new service:
- Has a `restart: unless-stopped` policy
- Is on the `tracing-net` network
- Has a Prometheus scrape target added to `observability/prometheus/prometheus.yml`

---

## Reporting Bugs

Please include:
- Debian version: `cat /etc/debian_version`
- Kernel version: `uname -r`
- Install flags used
- Full error message or log snippet from `/var/log/debian-trace-setup-*.log`
- Whether the issue is reproducible on a clean install

---

## Code of Conduct

Be respectful. This project exists to help engineers do deep systems work — keep discussions technical and constructive.
