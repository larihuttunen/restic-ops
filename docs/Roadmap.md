# Roadmap

This roadmap tracks the evolution of **restic-ops** from the current beta toward a stable `1.0.0`. It is operator-centric, emphasizes security (no plaintext passphrases on disk), and prioritizes reliability under automation.

**Semantic Versioning:**
- **MAJOR**: Breaking changes to CLI or behavior.
- **MINOR**: New features, backwards compatible.
- **PATCH**: Fixes or docs-only updates.

---

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
