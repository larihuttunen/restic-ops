# Releases

## How Releases Are Generated

We use a GitHub Actions workflow to automatically build and publish a release whenever a new tag (like `v1.0.0`) is pushed to the repository. The key steps performed by the workflow are:

- **Checkout**: The code is checked out from the repository.
- **Archive creation**: A compressed archive (`restic-ops.tar.gz`) is assembled from the components of the project you intend to distribute. In our standard configuration the workflow does: `tar -czf restic-ops.tar.gz bin/ systemd/ README.md Deployment.md`.
- **Self-extractor wrapper**: A small shell stub is prepended to the archive to produce a self-extracting executable (`restic-ops.run`). This stub prints an extraction message, finds the embedded tarball and unpacks it when run.
- **GPG signing**: The resulting self-extractor is signed with a GPG key. The private key and passphrase are pulled from the repository secrets (`GPG_PRIVATE_KEY` and `GPG_PASSPHRASE`). An ASCII-armored detached signature file (`restic-ops.run.asc`) is produced.
- **Release publication**: Both the `.run` archive and its `.asc` signature are attached to a GitHub Release corresponding to the tag, using the `softprops/action-gh-release` action.

The workflow YAML for this can be found in `.github/workflows/create-release.yml` and roughly implements the following commands:
```sh
tar -czf restic-ops.tar.gz bin/ systemd/ README.md Deployment.md
cat <<'EOF' > restic-ops.run
#!/bin/sh
echo "Extracting restic-ops..."
ARCHIVE_LINE=$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' "$0")
tail -n +${ARCHIVE_LINE} "$0" | tar xz
exit 0
__ARCHIVE_BELOW__
EOF
cat restic-ops.tar.gz >> restic-ops.run
chmod +x restic-ops.run
gpg --batch --yes --armor --detach-sign restic-ops.run
```

## Contents of a Release

When you download a release from the Releases page, you will find at least the following assets:

- `restic-ops.run`: the self-extracting archive including the project components.
- `restic-ops.run.asc`: the detached ASCII-armored signature for the `.run` file.

Inside the archive you will find the directories and files that were packaged at build time, for example: `bin/`, `systemd/`, `README.md`, `Deployment.md`. You can extract them by running `./restic-ops.run` on a Unix-like system, or by manually unpacking the tarball after stripping the self-extractor stub.

## Verifying a Release

To ensure that what you downloaded is authentic and unmodified, verify it with GnuPG. We attach a detached signature alongside the archive; here is how to check it:


When you download the self-extracting archive (the `.run` file) from our GitHub releases, it is accompanied by a detached signature file (the `.asc` file). Verifying the signature ensures you got an authentic, untampered copy of the release.

Follow these steps to verify the signature on your local machine:

1. **Obtain the maintainer’s public key**
   - If you have not done so already, import the project maintainer’s public key into your GnuPG keyring. The public key can be downloaded from a public keyserver, from the project repository or from the maintainer’s GitHub profile. Save it to a file, for example `maintainer-public-key.asc`.
   - Run the import command:
     ```sh
     gpg --import maintainer-public-key.asc
     ```
   - You should see output similar to:
     ```text
     gpg: key ABCDEF0123456789: public key "Your Name <you@example.com>" imported
     gpg: Total number processed: 1
     gpg:               imported: 1
     ```
   - If you do not already have the public key, ask the maintainer for it or fetch it from a keyserver:
     ```sh
     gpg --keyserver hkps://keys.openpgp.org --recv-keys ABCDEF0123456789
     ```
     Replace `ABCDEF0123456789` with the actual key ID published by the project.

2. **Download the archive and its signature**
   - From the GitHub Releases page for the version you want, download both `restic-ops.run` and `restic-ops.run.asc` to the same directory.

3. **Verify the signature**
   - Run the `gpg --verify` command:
     ```sh
     gpg --verify restic-ops.run.asc restic-ops.run
     ```
   - If the public key is not found in your keyring, GnuPG will print an error like:
     ```text
     gpg: Signature made ... using RSA key ID ABCDEF0123456789
     gpg: Can't check signature: No public key
     ```
     In that case, return to step 1 and import the correct public key.

4. **Interpret the output**
   - A successful verification looks like:
     ```text
     gpg: Signature made Thu 01 Jan 2021 12:34:56 PM UTC
     gpg:                using RSA key ABCDEF0123456789
     gpg: Good signature from "Your Name <you@example.com>" [ultimate]
     ```
     It means the archive is exactly what the maintainer signed and has not been altered. The key ID and name should match values published by the project. The `[ultimate]` or other trust indicator is the trust level assigned to the key in your keyring.
   - A bad signature prints:
     ```text
     gpg: Signature made ... using RSA key ID ABCDEF0123456789
     gpg: BAD signature from "Your Name <you@example.com>"
     ```
     which means the file may have been tampered with or corrupted; do **not** use it.

   - If the key you imported does not belong to the maintainer, the signature can still technically verify but the identity will not match what you expect. Always confirm the key fingerprint against what is published in the project documentation or by the maintainer:
     ```sh
     gpg --fingerprint ABCDEF0123456789
     ```
     The output shows the fingerprint; compare it to the known good fingerprint. If they match, the key is genuine.
