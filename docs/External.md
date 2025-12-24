# Manual External Disk Backup

This workflow addresses the "cold storage" use case, where backups are manually pushed to a physically connected external drive. It operates independently of the main automated system and relies on symmetric encryption to avoid complex key management.

## Architecture

The external backup process uses a standalone script and a dedicated configuration set. This prevents pollution of the main system's environment.

* **Script**: `backup-external.sh`
* The manual entry point. Handles validation, decryption, and execution.


* **Configuration**: `/etc/restic-ops/restic.env.external-disk.gpg`
* A symmetrically encrypted file containing the repository location and password.
* Requires a passphrase to decrypt (no private key needed).


* **Source List**: `/etc/restic-ops/include-external.txt`
* A plaintext list of absolute paths to back up.


* **Exclusions**: `/etc/restic-ops/exclude-external.txt`
* Standard patterns to exclude from the backup.



## The Canary Safety Check

To prevent data corruption or "empty" backups (which occur if a script runs while the drive is unmounted), this workflow enforces a **Canary System**.

* **Mechanism**: The script reads every path defined in `include-external.txt`.
* **Requirement**: It looks for a specific empty file named `.restic.marker` inside the root of that path.
* **Behavior**: If the marker is missing for any defined path, the script aborts immediately.

## Setup Guide

### Environment Configuration

Create a temporary plaintext environment file defining the `RESTIC_REPOSITORY` (path to the external drive) and `RESTIC_PASSWORD`. Encrypt this file using symmetric encryption (AES256 recommended):

```bash
gpg --symmetric --cipher-algo AES256 \
    --output /etc/restic-ops/restic.env.external-disk.gpg \
    external-temp.env

```

*You will be prompted to set a passphrase. This passphrase is required to run the backup. Securely remove the plaintext file after encryption.*

### Canary Creation

For every directory listed in `include-external.txt`, create the marker file.

```bash
touch /mnt/external-drive-mount/.restic.marker

```

## Usage

Connect the external drive and mount it to the expected location. Execute the script manually:

```bash
/usr/local/bin/restic-ops/bin/backup-external.sh

```

* **Authentication**: The GPG agent will prompt for the symmetric passphrase you set during encryption.
* **Verification**: The script will verify the existence of the canary markers.
* **Execution**: Restic initiates the backup using the decrypted credentials.
