# Changelog

All notable changes to this project will be documented in this file[cite: 19].

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)[cite: 19].

## [0.4.6] - 2026-08-27
### Fixed
- **Argument Parsing:** Fixed a bug in `stats.sh` where bare positional snapshot IDs (e.g., `--diff id1 id2`) were silently discarded by the `while` loop.
- **Snapshot Grouping:** Resolved an issue where `stats.sh --diff` failed on multi-path backups because `restic snapshots --latest 2` returned more than two IDs. Auto-fetched IDs are now strictly truncated to the latest two chronological snapshots.

## [0.4.5] - 2026-08-27
### Added
- **CLI Ergonomics:** Added direct flags (`--diff`, `--dirs`, `--top-files`) to `stats.sh` for faster analysis[cite: 19].
- **Smart Defaults:** `stats.sh --diff` now automatically defaults to comparing the latest 2 snapshots if `-L` is omitted[cite: 19].
- **External Backup Parity:** Ported proactive anomaly detection (GiB/TiB threshold and automated diffs) to `backup-external.sh`[cite: 19].

### Changed
- **External Backup Refactor:** Rewrote `backup-external.sh` for strict POSIX compliance (removed `bash` dependencies), unified it with `common.sh` for standard secrets loading, and replaced emojis with ASCII alert prefixes (`[INFO]`, `[ERROR]`, `[WARN]`, `[OK]`)[cite: 19].

### Fixed
- **Snapshot Parsing:** Fixed an `awk` regex bug in `stats.sh` where restic summary footers (e.g., "4 snapshots") were erroneously parsed as snapshot IDs[cite: 19].

## [0.4.4] - 2026-08-27
### Added
- **Proactive Anomaly Detection:** `backup.sh` now tracks storage growth and automatically triggers root-cause analysis on unexpected data spikes (GiB/TiB thresholds)[cite: 19].
- **Version Introspection:** Centralized tool versioning (`RESTIC_OPS_VERSION`) natively exposed across all shell commands via `common.sh` using the `-v` or `--version` flags[cite: 19].

### Changed
- **Diagnostic Stats:** Rebuilt `stats.sh` around actionable troubleshooting modes (`--mode top-files`, `dirs`, `diff`) for instant storage introspection, dropping passive JSON-passthrough[cite: 19].
- **Alert Formatting:** Replaced emojis with strict ASCII prefixes (`[ANOMALY]`, `[FAIL]`, `[OK]`) in `backup.sh` outputs to guarantee compatibility with `sieve`/`procmail` email routing[cite: 19].

## [0.4.3] - 2026-08-04
### Fixed
- **Linting:** Resolved multiple ShellCheck warnings across all shell scripts to improve POSIX compliance and execution safety[cite: 19].
- **Variable Assignment:** Fixed `SC1007` warnings by explicitly defining empty strings (`CDPATH=""`) in directory resolution commands[cite: 19].
- **External Script Sourcing:** Added ShellCheck directives (`# shellcheck source=bin/common.sh`) to properly lint external includes and fix `SC1091` warnings[cite: 19].
- **Subshell Masking:** Separated `GPG_TTY` declaration and assignment in `run.sh` to prevent masking subshell failure return codes (`SC2155`, `SC2046`)[cite: 19].
- **Read Command:** Added the `-r` flag to `read` commands in `run.sh` to prevent backslash mangling (`SC2162`)[cite: 19].

## [0.4.2]
### Fixed
- **Retention:** Make it possible to override a retention variable in the env file with an empty value (e.g., `KEEP_LAST=`)[cite: 19].

## [0.4.1]
### Added
- **Timer Persistence:** Added `Persistent=true` and `RandomizedDelaySec` to ensure missed jobs run upon system wake[cite: 19].
- **Power Awareness:** Implemented `ConditionACPower=true` in systemd services to skip heavy operations while on battery power[cite: 19].
- **Resilience:** Added `Restart=on-failure` logic to handle offline states or unprimed GPG agents gracefully[cite: 19].

## [0.4.0]
### Added
- **Cold Storage & External Media:**
  - **Standalone Script:** `backup-external.sh` with interactive "Lazy Initialization" for new drives[cite: 19].
  - **Symmetric Auth:** Leverages existing symmetric encryption support for keyless host operation[cite: 19].
  - **Configuration:** Isolated environment (`restic.env.external-disk.gpg`) with dedicated selection lists[cite: 19].
  - **Safety Canaries:** Mount verification (`.restic.marker`) to prevent empty backups[cite: 19].
  - **Documentation:** `docs/External.md` guide for air-gapped/cold-storage scenarios[cite: 19].

## [0.3.0]
### Added
- **Centralized Fleet Management:**
  - **Admin Console:** `bin/run.sh` "context switcher" to run tools locally using target secrets[cite: 19].
  - **Remote Health Checks:** `bin/check.sh` wrapper for `restic check` (cost-effective verification)[cite: 19].
  - **Robust Auth:** "Memory Pass-Through" strategy to bypass GPG Agent caching issues[cite: 19].
  - **Cache Safety:** Automatic redirection of cache directories when running in Admin Mode[cite: 19].

## [0.2.6]
### Changed
- **System Timers:** Reworked system timers and jobs for consistency across Linux and OpenBSD[cite: 19].

## [0.2.5]
### Added
- **Retention:** Manual retention policy support (`KEEP_LAST`, etc.)[cite: 19].

## [0.2.2] - [0.2.3]
### Fixed
- **OpenBSD Support:** POSIX compliance, `tar` vs `gtar` fixes, and `prime-gpg.sh` helper[cite: 19].

## [0.2.1]
### Added
- **Documentation:** Polish and lock removal guidance[cite: 19].

## [0.2.0-BETA]
### Added
- **Automation & Release Engineering:**
  - **Config Separation:** `/etc/restic-ops` for persistent config[cite: 19].
  - **Helpers:** Added `list.sh`, `stats.sh`, `prune.sh`[cite: 19].
  - **Automation:** Systemd units (timers/services) and Cron support[cite: 19].
  - **Security:** Integrated GPG-agent caching for non-interactive runs[cite: 19].
  - **Release:** Automated GitHub Actions pipeline producing GPG-signed installers[cite: 19].

## [0.1.0]
### Added
- **Baseline:**
  - Basic shell scripts: `backup.sh`, `restore.sh`, `retention.sh`[cite: 19].
  - Manual GPG passphrase handling[cite: 19].
