# Roadmap

This roadmap tracks the evolution of **restic-ops** from the current beta toward a stable `1.0.0`. It is operator-centric, emphasizes security (no plaintext passphrases on disk), and prioritizes reliability under automation.

**Semantic Versioning:**
- **MAJOR**: Breaking changes to CLI or behavior.
- **MINOR**: New features, backwards compatible.
- **PATCH**: Fixes or docs-only updates.

---

## Completed

### v0.1.0 — Baseline
- Basic shell scripts: `backup.sh`, `restore.sh`, `retention.sh`.
- Manual GPG passphrase handling.

### v0.2.0-BETA — Automation & Release Engineering
- **Config Separation:** `/etc/restic-ops` for persistent config.
- **Helpers:** Added `list.sh`, `stats.sh`, `prune.sh`.
- **Automation:** Systemd units (timers/services) and Cron support.
- **Security:** Integrated GPG-agent caching for non-interactive runs.
- **Release:** Automated GitHub Actions pipeline producing GPG-signed installers.

### v0.2.x — Deployment & Polish
- **v0.2.1:** Documentation polish and lock removal guidance.
- **v0.2.2 - v0.2.3 (OpenBSD):** POSIX compliance, `tar` vs `gtar` fixes, and `prime-gpg.sh` helper.
- **v0.2.5:** Manual retention policy support (`KEEP_LAST`, etc.).
- **v0.2.6:** System timers and job rework for consistency across Linux and OpenBSD.

### v0.3.0 — Centralized Fleet Management
- **Admin Console:** `bin/run.sh` "context switcher" to run tools locally using target secrets.
- **Remote Health Checks:** `bin/check.sh` wrapper for `restic check` (cost-effective verification).
- **Robust Auth:** "Memory Pass-Through" strategy to bypass GPG Agent caching issues.
- **Cache Safety:** Automatic redirection of cache directories when running in Admin Mode.

### v0.4.0 — Cold Storage & External Media
- **Standalone Script:** `backup-external.sh` with interactive "Lazy Initialization" for new drives.
- **Symmetric Auth:** Leverages existing symmetric encryption support for keyless host operation.
- **Configuration:** Isolated environment (`restic.env.external-disk.gpg`) with dedicated selection lists.
- **Safety Canaries:** Mount verification (`.restic.marker`) to prevent empty backups.
- **Documentation:** `docs/External.md` guide for air-gapped/cold-storage scenarios.

### v0.4.1 — Mobile & Power-Aware Automation
- **Timer Persistence:** Added `Persistent=true` and `RandomizedDelaySec` to ensure missed jobs run upon system wake.
- **Power Awareness:** Implemented `ConditionACPower=true` in systemd services to skip heavy operations while on battery power.
- **Resilience:** Added `Restart=on-failure` logic to handle offline states or unprimed GPG agents gracefully.

## Future Milestones

### v0.5.0 — Observability & DR
**Goal:** Proactive monitoring and disaster recovery.
- **Change Auditing:** `bin/diff.sh` wrapper to debug unexpected backup growth.
- **Metrics:** `bin/stats.sh --prometheus` or JSON output for monitoring agents (Zabbix/Datadog).
- **Mount Helper:** `bin/mount.sh` wrapper (FUSE) for interactive single-file recovery.
- **DR Guide:** `docs/DR.md` covering bare-metal recovery scenarios.

### v0.6.0 — Hardening & Policy
**Goal:** Advanced security features.
- **Passphrase Rotation:** Scripting to change the repository password safely.
- **Key Rotation:** Automated re-encryption of the local `restic.env.gpg` file.
- **Multiple Repos:** Support for `restic copy` to secondary remotes.
- **Immutable Backups:** Documentation/setup for Object Lock (S3).

### v1.0.0 — Stable Release
- API/Interface stability guarantee.
- Full test coverage.
- Complete documentation suite.
