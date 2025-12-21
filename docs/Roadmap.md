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

### v0.2.1 — Documentation & Reliability Polish (Current Focus)
**Goal:** Ensure the manual deployment process is frictionless and the existing scripts are robust.
- [x] **Docs:** Finalize `docs/Deployment.md` with tested, copy-paste friendly steps (verified on fresh VM).
- [x] **Docs:** Expand `docs/Admin.md` with restoration examples, service management, and **lock removal** (`restic unlock` guidance).
- [x] **Polish:** Ensure error messages in `common.sh` clearly indicate when GPG agent priming is missing.

### v0.2.2 Test on OpenBSD
**Goal:** Make sure that the releease works on OpenBSD
- [x] **restic-ops-run**: Tar vs. gtar compatibility.
- [x] **POSIX** compliance for scripts.
- [x] **Cron** setup works.
- [x] **prime-gpg.sh** helper script for GPG secret priming.

### v0.2.3 OpenBSD Functional
**Goal:** Make sure that the releease works on OpenBSD
- [x] Cron job validation
- [x] Deployment simplification.

### v0.2.5 Manual Use Case
**Goal:** Support a manual retention cycle.
- [x] Make retention.sh support manual retention.
- [x] Document manual retention example in Admin.md

### v0.2.x — Disaster Recovery (DR) Drills
**Goal:** Ensure operators can restore data when the house is on fire.
- [ ] **DR Guide:** `docs/DR.md` covering bare-metal recovery (OS + restic-ops + data).
- [ ] **Mount Helper:** `bin/mount.sh` wrapper to browse snapshots interactively (FUSE) for single-file recovery.
- [ ] **Restore Search:** `bin/find.sh` wrapper (using `restic find`) to locate lost files across snapshot history.
- [ ] **Test Protocol:** A standardized procedure for verifying backups (e.g., monthly "fire drill").

---

## 🔮 Future Milestones

### v0.3.0 — Health & Observability
**Goal:** Proactive monitoring and repository integrity without a monolithic CLI.
- **Health Check:** `bin/check.sh` wrapper for `restic check` using `--read-data-subset` for cost-effective integrity verification.
- **Change Auditing:** `bin/diff.sh` wrapper (using `restic diff`) to debug unexpected backup growth.
- **Metrics:** `bin/stats.sh --prometheus` or JSON output formatted for monitoring agents (Zabbix/Datadog).
- **Notifications:** Simple webhook integration (e.g., `bin/notify.sh` or common hook) for failure alerts.

### v0.4.0 — Hardening & Policy
**Goal:** Advanced security features.
- **Passphrase Rotation:** Documentation/scripting to change the repository password (restic key) and update `restic.env.gpg` safely.
- **Key Rotation:** Automated re-encryption of the local `restic.env.gpg` file (separate from repo password).
- **Multiple Repos:** Support for copying snapshots to a secondary remote (`restic copy`) for redundancy.
- **Immutable Backups:** Documentation/setup for Object Lock (S3) or Append-Only modes.

### v1.0.0 — Stable Release
- API/Interface stability guarantee.
- Full test coverage (CI/CD integration).
- Complete documentation suite (Install, Admin, Recovery, Architecture).
