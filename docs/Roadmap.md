# Roadmap

This roadmap tracks the evolution of **restic-ops** from the current `0.2.0-BETA` toward a stable `1.0.0`. It is operator‑centric, emphasizes security (no plaintext passphrases on disk), and prioritizes reliability under systemd.

Semantic versioning:
- **MAJOR**: breaking changes to CLI or behavior
- **MINOR**: new features, backwards compatible
- **PATCH**: fixes or docs-only updates

---

## 0.1.0 (latest released version)
**Goal:** Baseline backup/restore/retention with simple scripts.  
Deliverables: `bin/backup.sh`, `bin/restore.sh`, `bin/retention.sh`, `bin/common.sh`.  
Notes: Manual GPG passphrase handling; no systemd units or operator helpers.

---

## 0.2.0‑BETA (current branch: release/0.2.0-BETA)
**Goal:** Non‑interactive automation via **interactive gpg‑agent cache** under systemd; operator helpers.  
Deliverables:
- Systemd units (repo-local): backup/retention/prune (+ optional gpg‑agent)
- Helpers: `bin/list.sh`, `bin/stats.sh`, `bin/prune.sh`
- Update‑safe configuration model: `/etc/restic-ops`
- Docs: `docs/Deployment.md`, `docs/Admin.md`, `docs/CRON.md`

**Acceptance:**
- After priming the agent cache once, `restic-backup.service` & `restic-retention.service` run headless on test hosts.
- `list`, `stats`, `prune` operate correctly with filters.
- Documentation matches implementation.

---

## 0.2.1 — Deployment & Enablement
**Goal:** Make deployment repeatable and fast.  
Deliverables:
- `docs/deploy-0.2.md`: copy units, enable timers, prime cache, verify logs.
- Optional deployment script/Ansible role.
- Optional `EnvironmentFile=/etc/restic-ops/env` pattern for path overrides.

**Acceptance:**
- Fresh host setup ≤15 minutes, with a working first backup and visible timers.

---

## 0.2.2 — **Disaster Recovery (DR) v1: Runbook & Drill**
**Goal:** Operators can restore fast, under pressure.  
Deliverables:
- `docs/DR.md`:
  - **Recovery prerequisites** (GPG key/passphrase handling, agent priming)
  - **Single-file restore** and **directory restore** workflows
  - **Host‑level rebuild**: clean OS → install restic-ops → import config → restore `/etc` & critical paths
  - **Key loss playbook** (what’s recoverable, what isn’t)
- Testable examples using `bin/restore.sh` and `restic restore --target`.

**Acceptance:**
- DR **tabletop**: a new VM can be rebuilt from a blank state and restore `/etc` + at least one application directory using only `DR.md`.
- Measured, repeatable **RTO** target documented (e.g., “RTO ≤ 60 min for `/etc` + app dir”).
- Post‑mortem checklist template included in `docs/DR.md`.

---

## 0.3.0 — CLI consolidation & advanced ops
**Goal:** Single entrypoint with consistent UX.  
Deliverables:
- `bin/ops` with subcommands: `backup | restore | list | stats | retention | prune | check`
- Consistent flags, logging, exit codes; optional completions.

**Acceptance:**
- Existing scripts callable via `bin/ops` (or retained as shims).
- `bin/ops <cmd> --help` is consistent; smoke tests green.

---

## 0.4.0 — Observability & quality
**Goal:** Troubleshoot faster, scale confidently.  
Deliverables:
- Structured & human logs; syslog/file logging options.
- CI lint/tests with a throwaway repo; basic integration flow.

**Acceptance:**
- CI gates PRs; failures include actionable context.

---

## 0.5.x — Key management & **DR v2: Evidence-based recovery**
**Goal:** Hardening secrets & validating restores with checks.  
Deliverables:
- Passphrase rotation procedure (documented & rehearsed).
- `bin/check.sh` for `restic check` & repository health.
- Optional: TPM/HSM/KMS design spike.
- DR **validation job**: scheduled `restic check` + sample restore to a scratch path; retention of validation logs.

**Acceptance:**
- Rotation procedure exercised successfully on a non-prod repo.
- Periodic validation runs produce logs; errors alert operators.

---

## 0.6.x — DR v3: Automation & metrics
**Goal:** Lower RTO/RPO, higher assurance.  
Deliverables:
- Optional automated **selective restore tests** with integrity checks.
- Metrics surfaced (JSON logs from `list/stats/check`) for dashboards.
- Optional: dry-run restore diffing vs. golden manifests.

**Acceptance:**
- At least one periodic auto-restore test runs and reports success metrics.

---

## 1.0.0 — Stable CLI/UX
**Goal:** “It just works.”  
Definition of Done:
- Stable CLI contract & migration notes.
- Complete docs: deploy, operate, **recover**, maintain, troubleshoot.
- Backward compatibility within 1.x; breaking changes → MAJOR.
