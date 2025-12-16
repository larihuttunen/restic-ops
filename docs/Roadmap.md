# Roadmap

This document outlines a rough roadmap for the project, starting at version 0.1.0. It is meant to guide development, align expectations, and set milestones while we flesh out features beyond the basic backup/restore/retention functionality currently provided by the scripts: common.sh, backup.sh, restore.sh, retention.sh.

## Versioning and Milestones
Use semantic versioning. Starting in the 0.x range signals early development; stable interfaces and backward compatibility come once we hit 1.0.0.

### 0.1.0 (Initial Alpha)
- Baseline: implement basic backup, restore, retention. These are the scripts you see today and constitute the starting point.

### 0.2.0 (Alpha → Beta Transition)
- **List snapshots**: add a `list` subcommand or script to view existing backup IDs (`restic snapshots`).
- Better documentation: expand README/Deployment, include usage examples for list, backup, restore, retention.
- Basic error handling and input validation; handle common failure cases gracefully.

### 0.3.0 (Beta)
- **Stats & Check**: wrap `restic stats` (or `restic snapshots --json` info) and `restic check` to report repository status and integrity.
- Flexible retention: expose more restic `forget` options (keep-last, keep-hourly, etc.), customizable via command-line or config.
- Pre/post hooks: allow user-defined commands to run before or after backups.

### 0.4.0 (Beta)
- **Tagging support**: allow passing tags into backups and filtering snapshots by tag later (`restic tag add`, `restic snapshots --tag`).
- Improved filtering of snapshots (by host, date, tag).
- Possibly implement selective restore wrappers for easier file/directory extraction.

### 0.5.0 (Release Candidate)
- **Mount**: convenience wrapper to mount a restic repository (`restic mount`).
- **Diff**: wrap `restic diff` for comparing two snapshots.
- Consolidate and polish scripts: unify argument parsing, centralize common functionality more completely in `common.sh`.
- Add automated tests (unit/integration or manual test checklists) and CI for quality assurance.

### 0.6.0 → 0.9.x (Final Beta → RC)**
- Address user feedback from earlier betas. Fix bugs (patch bumps), refine the UI/UX (improved logging, color, prompts).
- Tackle other restic capabilities: incremental backup tweaks, prune enhancements (e.g. dry-run mode), key management support (change passwords or keys), snapshots pruning beyond what the basic policy covers.
- Explore optional features: cache management (`restic cache`), automatic snapshots tagging via timestamp/hostname patterns, integration with restic’s rest-server or other backends.

### 1.0.0 (Stable)
- Polished, tested, documented and stable API. All planned features for the first generation delivered and working reliably.
- Guarantee backward compatibility for the public interface (script names, arguments, meaning).
- Revisit version bump to 1.0.0; from here on follow normal MAJOR.MINOR.PATCH lifecycle: new features → MINOR, bug fixes → PATCH, breaking changes → MAJOR.

## Other Potential Features & Enhancements
- Interactive menus or basic TUI (text UI) for less experienced users: choose snapshots from a list in a friendly way.
- Configuration file support: centralize defaults (repository path, retention rules, includes/excludes) in a config rather than environment variables only.
- Logging improvements: rotate logs, configurable verbosity, logging to file or syslog.
- Cross-platform support: test & adapt scripts for other shells or OSes if necessary (FreeBSD, macOS) and document portability considerations.
- Docker images or containerized helpers for easier deployment.
- Integration with other backup orchestration tools or scheduling frameworks beyond cron (systemd timers, Kubernetes CronJobs).

## Contributors & Feedback
- Invite early users to try the various pre-releases and contribute feedback or code.
- Track bugs, feature requests and priorities in issues or a project board.

