# install-qpdf.ps1 - run by setup.exe (elevated) to install qpdf via winget
# Exit codes: 0 = qpdf present, 10 = winget not found, 11 = winget ran but qpdf not found
param([string]$LogPath = "$env:TEMP\qpdf-gui-install-qpdf.log")

function Test-Qpdf { [bool](Get-ChildItem "$env:ProgramFiles\qpdf*\bin\qpdf.exe" -ErrorAction SilentlyContinue) }
function Log($m) { Add-Content -LiteralPath $LogPath -Value ("[{0}] {1}" -f (Get-Date -Format s), $m) }

Log "Starting qpdf install check"
if (Test-Qpdf) { Log "qpdf already installed - nothing to do"; exit 0 }

# Locate winget (app alias for current user, else the system App Installer package)
$winget = (Get-Command winget.exe -ErrorAction SilentlyContinue).Source
if (-not $winget) {
    $p = Resolve-Path "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue |
         Sort-Object Path -Descending | Select-Object -First 1
    if ($p) { $winget = $p.Path }
}
if (-not $winget) { Log "winget not found"; exit 10 }
Log "Using winget: $winget"

$out = & $winget install --id QPDF.QPDF -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1
Log ("winget exit code: {0}" -f $LASTEXITCODE)
Log ($out | Out-String)

if (Test-Qpdf) { Log "qpdf installed OK"; exit 0 }
Log "qpdf.exe not found after winget run"
exit 11
