# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x (latest) | ✅ Yes |

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Please report security issues by emailing: `security@yourproject.example`  
Or open a [GitHub Security Advisory](https://github.com/youruser/debian-trace-pro/security/advisories/new) (private).

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix if known

You will receive a response within 48 hours. We aim to patch confirmed issues within 14 days.

## Security Considerations

This project installs system-level tooling and modifies kernel parameters. Please be aware:

- **`kernel.kptr_restrict = 0`** — set for symbol resolution. Revert to `1` on hardened systems.
- **`kernel.perf_event_paranoid = 1`** — allows non-root perf usage. Set to `2` or `3` to restrict.
- **ClickHouse** runs with no authentication by default — add credentials before network exposure.
- **Grafana** uses `admin/tracepro2024` — change immediately in production.
- **BPF programs** require `CAP_BPF` or root — scope access with the `tracing` group.
- **Docker socket** is exposed to the `docker` group — only add trusted users.

Always review `install.sh` before running as root on any system.
