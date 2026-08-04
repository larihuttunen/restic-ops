# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.3] - 2026-08-04
### Fixed
- **Linting:** Resolved multiple ShellCheck warnings across all shell scripts to improve POSIX compliance and execution safety.
- **Variable Assignment:** Fixed `SC1007` warnings by explicitly defining empty strings (`CDPATH=""`) in directory resolution commands.
- **External Script Sourcing:** Added ShellCheck directives (`# shellcheck source=bin/common.sh`) to properly lint external includes and fix `SC1091` warnings.
- **Subshell Masking:** Separated `GPG_TTY` declaration and assignment in `run.sh` to prevent masking subshell failure return codes (`SC2155`, `SC2046`).
- **Read Command:** Added the `-r` flag to `read` commands in `run.sh` to prevent backslash mangling (`SC2162`).

## [0.4.2]
### Fixed
- **Retention:** Make it possible to override a retention variable in the env file with an empty value (e.g., `KEEP_LAST=`).

## [0.4.1]
### Added
- **Timer Persistence:** Added `Persistent=true` and `RandomizedDelaySec` to ensure missed jobs run upon system wake.
- **Power Awareness:** Implemented `ConditionACPower=true` in systemd services to skip heavy operations while on battery power.
- **Resilience:** Added `Restart=on-failure` logic to handle offline states or unprimed GPG agents gracefully.

## [0.4.0]
### Added
- **Cold Storage & External Media:**
  - **Standalone Script:** `backup-external.sh` with interactive "Lazy Initialization" for new drives.
  - **Symmetric Auth:** Leverages existing symmetric encryption support for keyless host operation.
  - **Configuration:** Isolated environment (`restic.env.external-disk.gpg`) with dedicated selection lists.
  - **Safety Canaries:** Mount verification (`.restic.marker`) to prevent empty backups.
  - **Documentation:** `docs/External.md` guide for air-gapped/cold-storage scenarios.

## [0.3.0]
### Added
- **Centralized Fleet Management:**
  - **Admin Console:** `bin/run.sh` "context switcher" to run tools locally using target secrets.
  - **Remote Health Checks:** `bin/check.sh` wrapper for `restic check` (cost-effective verification).
  - **Robust Auth:** "Memory Pass-Through" strategy to bypass GPG Agent caching issues.
  - **Cache Safety:** Automatic redirection of cache directories when running in Admin Mode.

## [0.2.6]
### Changed
- **System Timers:** Reworked system timers and jobs for consistency across Linux and OpenBSD.

## [0.2.5]
### Added
- **Retention:** Manual retention policy support (`KEEP_LAST`, etc.).

## [0.2.2] - [0.2.3]
### Fixed
- **OpenBSD Support:** POSIX compliance, `tar` vs `gtar` fixes, and `prime-gpg.sh` helper.

## [0.2.1]
### Added
- **Documentation:** Polish and lock removal guidance.

## [0.2.0-BETA]
### Added
- **Automation & Release Engineering:**
  - **Config Separation:** `/etc/restic-ops` for persistent config.
  - **Helpers:** Added `list.sh`, `stats.sh`, `prune.sh`.
  - **Automation:** Systemd units (timers/services) and Cron support.
  - **Security:** Integrated GPG-agent caching for non-interactive runs.
  - **Release:** Automated GitHub Actions pipeline producing GPG-signed installers.

## [0.1.0]
### Added
- **Baseline:**
  - Basic shell scripts: `backup.sh`, `restore.sh`, `retention.sh`.
  - Manual GPG passphrase handling.
