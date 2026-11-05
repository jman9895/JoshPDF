# Developer notes

[← Back to README](../README.md) · [User guide](USER-GUIDE.md) · [Installation](INSTALLATION.md)

## Source map

| File | Role |
|---|---|
| `qpdf-gui.ps1` | Windows Forms UI, PDF enumeration, qpdf process handling, output mapping, log and failure report |
| `qpdf-gui.cmd` | Hidden-console Windows PowerShell launcher in STA mode |
| `qpdf-gui.ico` | GUI and installer icon |
| `install-qpdf.ps1` | Elevated dependency detection and winget installation helper |
| `qpdf-gui.iss` | Inno Setup definition, shortcuts, dependency hook, and uninstall cleanup |
| `build.cmd` | Find/install Inno Setup 6 and invoke its compiler |
| `.gitattributes` | CRLF checkout for Windows scripts and binary handling for images/icons |
| `.gitignore` | Exclude build outputs, bundled dependency folders, logs, installers, and Word reference documents |
| `docs/` | Public operating guides, implementation notes, screenshots, and checksum reference |

The original operator notes have been reorganized into these guides. The private Word reference manual, internal source locations, and client-project references are deliberately not tracked. Public source files retain the supplied application behavior and publisher metadata.

## Processing model

The UI runs a sequential loop. Folder input enumerates `*.pdf` and snapshots the file list before processing. Each relative path is mapped beneath the output root; matching input/output roots receive the `-decrypted` suffix. Existing output is skipped unless overwrite is enabled.

`Invoke-Qpdf` starts qpdf with `UseShellExecute = false`, redirects both streams, and begins asynchronous reads on both streams before waiting. During its polling loop, Windows Forms `DoEvents()` keeps the interface responsive. Stop sets a flag checked between files; it does not terminate the active process. This is a single-threaded UI loop, not a background worker.

The process arguments are assembled into one string:

```text
qpdf --decrypt "input.pdf" "output.pdf"
qpdf --decrypt --password=KnownOpenPassword "input.pdf" "output.pdf"
```

The actual script quotes the password argument and escapes embedded quotes. Review argument escaping and edge-case passwords when changing process launch behavior. Passwords are process arguments, not secure secret-channel inputs.

Exit `0` increments OK; exit `3` increments WARN; all other qpdf codes increment failure and trigger best-effort output deletion. Exceptions are reported separately. Warnings do not imply a specific repair was performed. The app does not automatically inspect output encryption or document fidelity.

## Build an installer

1. Clone the repository on a Windows build workstation.
2. Review and update `AppVersion` in `qpdf-gui.iss` for a new binary version.
3. Run `build.cmd`. It searches standard Inno Setup 6 locations and attempts `winget install --id JRSoftware.InnoSetup -e` if needed.
4. Collect `output\qpdf-gui-setup-<version>.exe`.
5. Perform the Windows checks below, generate a checksum, and attach the installer to a matching GitHub Release.

No qpdf binaries are bundled in the supplied source. The helper installs qpdf during setup. Keep runtime dependency versions and build-tool versions in your release records if you need reproducible releases. The uploaded v1.1.1 EXE has not been rebuilt in this documentation update.

## Lessons retained from the original build notes

### Format a string before calling AppendText

Build the log line first, then pass a single string to the .NET method. This avoids PowerShell comma/argument parsing surprises around the format operator:

```powershell
$line = '[{0}] {1}' -f $timestamp, $message
$log.AppendText($line)
```

### Avoid automatic variable names

Use `$argList`, as the application does, rather than repurposing PowerShell's automatic `$args` variable.

### Keep Inno Setup quoting explicit

Shortcut parameters contain nested quotes around script paths. The supplied `.iss` writes parameter strings directly instead of using a preprocessor definition containing doubled quotes; preserve this quoting when editing paths with spaces.

### Preserve Windows line endings

`.cmd`, `.bat`, `.iss`, and `.ps1` use CRLF on checkout through `.gitattributes`. In particular, batch labels and `goto` flow should be tested from a normal Windows checkout.

### Test elevated dependency discovery

An elevated user can have different command aliases and package registration than an unelevated user. The WindowsApps fallback is intended for interactive installation and is not a guarantee of SYSTEM-context support.

## Known implementation limits

- Output roots nested inside input are not excluded from later enumeration. In-place suffixes can collide with existing input/output filenames.
- Overwrite has no transaction, staging file, or backup. A failed invocation can remove an existing destination; exception paths can leave partial files.
- The run handler lacks an outer `try/finally` to reliably restore controls after directory creation or report-writing errors.
- The GUI pumps events during work. Some inputs/options remain editable; avoid changing controls or closing the form mid-run until those behaviors receive dedicated handling.
- There is no full persistent session log, automated output check, credential store, job queue, or cloud processing service.
- File existence checks are not uniformly literal-path operations; test wildcard characters and unusual paths before relying on them in production batches.
- Dependency discovery sorts full paths lexically; the setup helper searches fewer locations than the GUI.
- `build.cmd` is an interactive convenience wrapper with a pause, not a CI build contract with reliable failure exit codes.

## Windows validation checklist

- Clean installation with and without qpdf already installed; verify shortcuts, elevation, and uninstall behavior.
- Missing winget and offline dependency handling, including helper log and exit codes.
- Launch from source and installed shortcuts; confirm icon and executable discovery.
- Single restricted PDF and nested folder batch; inspect content, text, and output encryption.
- Known open password, incorrect password, and mixed-password batches.
- Existing output skip and intentional overwrite in disposable folders.
- qpdf warning, malformed PDF, access-denied output, and partial-output failure cases.
- Stop during a multi-file job; confirm current-file completion and remaining files are not processed.
- Paths with spaces, Unicode, and wildcard characters; passwords with quotation marks and trailing backslashes.
- Empty input folder, same-root output, nested output, and repeated-run collision behavior using test copies only.

Repository preparation included source review, documentation/link checks, and checksums. It did not execute the Windows GUI, build an installer, or prove source/binary equivalence. The supplied screenshots illustrate the original application's interface and successful run.

## Roadmap ideas

These are ideas, not implemented features or delivery commitments:

- Sign installers as part of release builds. Signing improves publisher identity but does not guarantee SmartScreen reputation or suppress every warning.
- Package a validated qpdf dependency for Intune/managed offline deployments, with required license notices.
- Add a startup indicator for slow initial launches.
- Add robust cancellation, input locking, error cleanup, safe output staging, and explicit nested-output exclusion.
- Add optional persistent logs and output verification.
- Explore SharePoint-triggered processing with a separate service and pikepdf; no cloud component currently exists in this repository.
