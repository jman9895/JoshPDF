# Installation and IT reference

[← Back to README](../README.md) · [User guide](USER-GUIDE.md)

## Requirements

Use Windows 10/11 x64 with Windows PowerShell 5.1 and Windows Forms. The GUI needs an accessible qpdf executable and a writable output folder. Setup requires administrator approval and uses winget to acquire qpdf if the helper does not detect it. Winget availability varies by Windows installation and user context; install or repair App Installer if needed.

## Install v1.1.1

1. Get `qpdf-gui-setup-1.1.1.exe` from [GitHub Releases](https://github.com/jman9895/JoshPDF/releases/tag/v1.1.1).
2. Compare its SHA-256 with the [published checksum](CHECKSUMS.md).
3. Run setup, approve UAC, and select the desired shortcut options.
4. Wait for the qpdf dependency step. If it fails, the GUI remains installed; follow the manual dependency steps below.
5. Launch **qpdf GUI** from Start or the optional desktop shortcut.

The supplied executable is unsigned. Windows may show an unknown-publisher or SmartScreen prompt. Review the source, origin, and checksum before deciding to proceed; this project does not provide an Authenticode trust signature. A checksum verifies matching bytes, not publisher identity or safety.

## What setup installs

| Item | Default location or behavior |
|---|---|
| GUI source and icon | `C:\Program Files\qpdf GUI\qpdf-gui.ps1` and `qpdf-gui.ico` |
| Dependency helper | Extracted to setup's temporary directory, then deleted after installation |
| Dependency log | `C:\Program Files\qpdf GUI\install-qpdf.log` |
| qpdf | Installed separately via the `QPDF.QPDF` winget package |
| Start Menu | Shortcut for all users |
| Desktop | Optional shortcut |
| Uninstall entry | **qpdf GUI** in Windows installed apps |

The supplied Inno Setup definition identifies **Echostor Technologies** as publisher and version **1.1.1**. The release executable is the uploaded artifact, not a newly rebuilt installer. Its byte-for-byte correspondence with the supplied source has not been established by a reproducible build.

## Manual qpdf installation

```powershell
winget install --id QPDF.QPDF -e
```

Use the exact package ID to avoid ambiguous search matches. Alternatively, use the [official qpdf releases](https://github.com/qpdf/qpdf/releases), install/extract the appropriate Windows package, then browse to its executable in the GUI.

## Run from source

Keep `qpdf-gui.ps1`, `qpdf-gui.cmd`, and preferably `qpdf-gui.ico` together. Install qpdf separately and double-click `qpdf-gui.cmd`. The launcher invokes Windows PowerShell with `-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden`; this is a process-level execution-policy option, not a machine-wide policy change. Organization application-control policies can still block execution.

## qpdf discovery

The GUI checks:

1. `qpdf\bin\qpdf.exe` beside the script.
2. `qpdf.exe` on PATH.
3. Matching `qpdf*\bin\qpdf.exe` under Program Files and Program Files (x86), sorted by full path descending.

The final search is lexical, not semantic version sorting; it does not guarantee the highest version when multiple installations exist. Use **Browse…** to select the intended executable.

The installation helper uses a narrower detection check: only Program Files matching paths. A PATH-only or bundled installation may work in the GUI while the helper still attempts a winget install.

## Silent installation

```text
qpdf-gui-setup-1.1.1.exe /VERYSILENT /SUPPRESSMSGBOXES
```

Run in an approved elevated interactive-user context with winget and internet available. The dependency helper accepts winget source/package agreements through its command switches; review the relevant package terms before organizational deployment. Silent mode skips the postinstall GUI launch. Inspect the dependency log: setup can finish installing the GUI even if qpdf installation fails.

This is not a tested Intune/SYSTEM deployment method. A future Win32 deployment should package and validate the dependency explicitly rather than assume the user's winget registration is available.

## Dependency log and helper exit codes

| Code | Meaning |
|---|---|
| `0` | Helper found qpdf before or after the installation attempt |
| `10` | Helper could not locate winget |
| `11` | winget ran, but the helper's Program Files check still did not find qpdf |

These are `install-qpdf.ps1` codes, not a complete contract for the outer setup executable. The helper logs winget output and its return code; its final success decision is based on the executable search. It tries the current user's winget command first, then an x64 App Installer path beneath WindowsApps. Elevated or SYSTEM contexts can differ from an ordinary user's session.

## Uninstall

Remove **qpdf GUI** through Windows Settings → Apps. Its installer also removes `install-qpdf.log`. qpdf is a separate dependency and remains installed; remove it separately if no other application needs it. User PDF inputs, output copies, and failure reports are not registered for deletion by this setup definition.
