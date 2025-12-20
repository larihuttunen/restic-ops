# Roadmap

This roadmap tracks the evolution of **restic-ops** from the current beta toward a stable `1.0.0`. It is operator‑centric, emphasizes security (no plaintext passphrases on disk), and prioritizes reliability under systemd.

**Semantic Versioning:**
- **MAJOR**: Breaking changes to CLI or behavior.
- **MINOR**: New features, backwards compatible.
- **PATCH**: Fixes or docs-only updates.

---

## ✅ Completed

### v0.1.0 — Baseline
- Basic shell scripts: `backup.sh`, `restore.sh`, `retention.sh`.
- Manual GPG passphrase handling.

### v0.2.0-BETA — Automation & Release Engineering
- **Config Separation:** `/etc/restic-ops` for persistent config.
- **Helpers:** Added `list.sh`, `stats.sh`, `prune.sh`.
- **Automation:** Systemd units (timers/services) and Cron support added.
- **Security:** Integrated GPG-agent caching for non-interactive runs.
- **Release Engineering:** Automated GitHub Actions pipeline producing GPG-signed self-extracting installers (`.run` files).

---

## 🚧 In Progress: v0.2.x — Deployment & Hardening

### v0.2.1 — Streamlined Deployment (Current Focus)
**Goal:** Make installation fast, repeatable, and less error-prone.
- [ ] **Installer Script:** A `install.sh` helper that automates directory creation, symlinking, and permission checks.
- [ ] **Validation:** `bin/check-config.sh` to verify GPG agent status and config syntax before running jobs.
- [ ] **Docs:** Finalize `docs/Deployment.md` with "copy-paste" friendly steps.

### v0.2.2 — Disaster Recovery (DR) Drills
**Goal:** Ensure operators can restore data when the house is on fire.
- [ ] **DR Guide:** `docs/DR.md` covering bare-metal recovery (OS + restic-ops + data).
- [ ] **Restore Helper:** Interactive mode for `bin/restore.sh` to browse snapshots if no ID is provided.
- [ ] **Test Protocol:** A standardized procedure for verifying backups (e.g., monthly "fire drill").

---

## 🔮 Future Milestones

### v0.3.0 — The Unified CLI (`ops`)
**Goal:** Replace loose scripts with a single, cohesive entry point.
- Consolidate `bin/*.sh` into a single tool: `ops backup`, `ops restore`, `ops status`.
- Consistent flag parsing and logging across all commands.
- **Self-Update:** `ops update` to pull the latest signed release.

### v0.4.0 — Health & Observability
**Goal:** Proactive monitoring.
- **Health Check:** `ops check` wrapper for `restic check` with parsing for alerting.
- **Metrics:** `ops stats --prometheus` or JSON output formatted for monitoring agents (Zabbix/Datadog).
- **Notifications:** Simple webhook support (Slack/Discord/Email) on failure.

### v0.5.0 — Hardening & Policy
- **Key Rotation:** Automated re-encryption of `restic.env.gpg`.
- **Multiple Repos:** Support for syncing to a secondary remote (e.g., local NAS + S3).
- **Immutable Backups:** Documentation/setup for Object Lock (S3) or Append-Only modes.

### v1.0.0 — Stable Release
- API/CLI stability guarantee.
- Full test coverage (CI/CD integration).
- Complete documentation suite (Install, Admin, Recovery, Architecture).
