<#
  qpdf-gui.ps1 - Simple GUI to strip PDF restrictions with qpdf --decrypt
  - Input: a single PDF or a folder (optionally including subfolders)
  - Output: a folder (subfolder structure is preserved)
  - Shows a live log and writes a failure list (TXT) to the output folder
  Run with: qpdf-gui.cmd  (or: powershell -NoProfile -ExecutionPolicy Bypass -STA -File qpdf-gui.ps1)
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------- Find qpdf ----------
function Find-Qpdf {
    # 1. qpdf bundled next to this script (installed version)
    $bundled = Join-Path $PSScriptRoot "qpdf\bin\qpdf.exe"
    if (Test-Path $bundled) { return $bundled }
    # 2. On PATH, 3. Program Files
    $cmd = Get-Command qpdf.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $hits = Get-ChildItem "$env:ProgramFiles\qpdf*\bin\qpdf.exe", "${env:ProgramFiles(x86)}\qpdf*\bin\qpdf.exe" -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending
    if ($hits) { return $hits[0].FullName }
    return ""
}

# ---------- Form ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "qpdf - Remove PDF Restrictions"
$form.Size = New-Object System.Drawing.Size(780, 600)
$form.MinimumSize = New-Object System.Drawing.Size(640, 480)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$iconPath = Join-Path $PSScriptRoot "qpdf-gui.ico"
if (Test-Path $iconPath) { try { $form.Icon = New-Object System.Drawing.Icon($iconPath) } catch {} }

function New-Label($text, $x, $y) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text; $l.Location = New-Object System.Drawing.Point($x, $y); $l.AutoSize = $true
    $form.Controls.Add($l); $l
}
function New-TextBox($x, $y, $w) {
    $t = New-Object System.Windows.Forms.TextBox
    $t.Location = New-Object System.Drawing.Point($x, $y); $t.Width = $w
    $t.Anchor = "Top, Left, Right"
    $form.Controls.Add($t); $t
}
function New-Button($text, $x, $y, $w = 80) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text; $b.Location = New-Object System.Drawing.Point($x, $y); $b.Width = $w
    $b.Anchor = "Top, Right"
    $form.Controls.Add($b); $b
}

# qpdf.exe
New-Label "qpdf.exe:" 12 15 | Out-Null
$txtQpdf = New-TextBox 110 12 540
$txtQpdf.Text = Find-Qpdf
$btnQpdf = New-Button "Browse..." 660 10 90

# Input
New-Label "Input:" 12 48 | Out-Null
$txtIn = New-TextBox 110 45 450
$btnInFile   = New-Button "File..."   570 43 85
$btnInFolder = New-Button "Folder..." 660 43 90

# Output
New-Label "Output folder:" 12 81 | Out-Null
$txtOut = New-TextBox 110 78 540
$btnOut = New-Button "Browse..." 660 76 90

# Password
New-Label "Open password:" 12 114 | Out-Null
$txtPw = New-Object System.Windows.Forms.TextBox
$txtPw.Location = New-Object System.Drawing.Point(110, 111); $txtPw.Width = 200
$txtPw.UseSystemPasswordChar = $true
$form.Controls.Add($txtPw)
New-Label "(optional - only if PDFs need a password to open)" 318 114 | Out-Null

# Options
$chkRecurse = New-Object System.Windows.Forms.CheckBox
$chkRecurse.Text = "Include subfolders"; $chkRecurse.Location = New-Object System.Drawing.Point(110, 142)
$chkRecurse.AutoSize = $true; $chkRecurse.Checked = $true
$form.Controls.Add($chkRecurse)

$chkOverwrite = New-Object System.Windows.Forms.CheckBox
$chkOverwrite.Text = "Overwrite existing output files"; $chkOverwrite.Location = New-Object System.Drawing.Point(260, 142)
$chkOverwrite.AutoSize = $true
$form.Controls.Add($chkOverwrite)

# Run / Stop
$btnRun  = New-Button "Run"  580 138 80
$btnStop = New-Button "Stop" 670 138 80
$btnStop.Enabled = $false

# Progress
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(12, 175); $progress.Width = 738
$progress.Anchor = "Top, Left, Right"
$form.Controls.Add($progress)

# Log
$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true; $log.ScrollBars = "Both"; $log.WordWrap = $false; $log.ReadOnly = $true
$log.Font = New-Object System.Drawing.Font("Consolas", 9)
$log.Location = New-Object System.Drawing.Point(12, 205); $log.Size = New-Object System.Drawing.Size(738, 310)
$log.Anchor = "Top, Bottom, Left, Right"
$form.Controls.Add($log)

$status = New-Object System.Windows.Forms.Label
$status.Location = New-Object System.Drawing.Point(12, 525); $status.AutoSize = $true
$status.Anchor = "Bottom, Left"
$form.Controls.Add($status)

$btnOpenOut = New-Object System.Windows.Forms.Button
$btnOpenOut.Text = "Open output folder"; $btnOpenOut.Width = 140
$btnOpenOut.Location = New-Object System.Drawing.Point(610, 520); $btnOpenOut.Anchor = "Bottom, Right"
$form.Controls.Add($btnOpenOut)

function Write-Log($msg) {
    $line = "[{0}] {1}`r`n" -f (Get-Date -Format "HH:mm:ss"), $msg
    $log.AppendText($line)
    [System.Windows.Forms.Application]::DoEvents()
}

# ---------- Browse handlers ----------
$btnQpdf.Add_Click({
    $d = New-Object System.Windows.Forms.OpenFileDialog
    $d.Filter = "qpdf.exe|qpdf.exe|Executables (*.exe)|*.exe"
    if ($d.ShowDialog() -eq "OK") { $txtQpdf.Text = $d.FileName }
})
$btnInFile.Add_Click({
    $d = New-Object System.Windows.Forms.OpenFileDialog
    $d.Filter = "PDF files (*.pdf)|*.pdf"
    if ($d.ShowDialog() -eq "OK") {
        $txtIn.Text = $d.FileName
        if (-not $txtOut.Text) { $txtOut.Text = Join-Path (Split-Path $d.FileName) "Decrypted" }
    }
})
$btnInFolder.Add_Click({
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = "Select the input folder"
    if ($d.ShowDialog() -eq "OK") {
        $txtIn.Text = $d.SelectedPath
        if (-not $txtOut.Text) { $txtOut.Text = $d.SelectedPath.TrimEnd('\') + "_Decrypted" }
    }
})
$btnOut.Add_Click({
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = "Select the output folder"
    if ($d.ShowDialog() -eq "OK") { $txtOut.Text = $d.SelectedPath }
})
$btnOpenOut.Add_Click({
    if ($txtOut.Text -and (Test-Path $txtOut.Text)) { Start-Process explorer.exe $txtOut.Text }
})

$script:stopRequested = $false
$btnStop.Add_Click({ $script:stopRequested = $true; Write-Log "Stop requested - finishing current file..." })

# ---------- Run qpdf on one file ----------
function Invoke-Qpdf($qpdf, $inFile, $outFile, $password) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $qpdf
    $argList = @('--decrypt')
    if ($password) { $argList += ('"--password=' + ($password -replace '"', '\"') + '"') }
    $argList += ('"' + $inFile + '"'), ('"' + $outFile + '"')
    $psi.Arguments = $argList -join ' '
    $psi.UseShellExecute = $false
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardOutput = $true
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $p.StandardOutput.ReadToEndAsync()
    $stderrTask = $p.StandardError.ReadToEndAsync()
    while (-not $p.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }
    $p.WaitForExit()
    [pscustomobject]@{
        ExitCode = $p.ExitCode
        Message  = (($stderrTask.Result + " " + $stdoutTask.Result) -replace '\s+', ' ').Trim()
    }
}

# ---------- Main run ----------
$btnRun.Add_Click({
    $qpdf = $txtQpdf.Text.Trim('" ')
    $in   = $txtIn.Text.Trim('" ')
    $out  = $txtOut.Text.Trim('" ')

    if (-not (Test-Path $qpdf -PathType Leaf)) { [System.Windows.Forms.MessageBox]::Show("qpdf.exe not found. Use Browse to locate it.", "qpdf GUI") | Out-Null; return }
    if (-not (Test-Path $in)) { [System.Windows.Forms.MessageBox]::Show("Input file/folder not found.", "qpdf GUI") | Out-Null; return }
    if (-not $out) { [System.Windows.Forms.MessageBox]::Show("Choose an output folder.", "qpdf GUI") | Out-Null; return }

    # Build file list
    if (Test-Path $in -PathType Leaf) {
        $inRoot = Split-Path $in
        $files = @(Get-Item -LiteralPath $in)
    } else {
        $inRoot = (Resolve-Path -LiteralPath $in).Path.TrimEnd('\')
        $files = @(Get-ChildItem -LiteralPath $inRoot -Filter *.pdf -File -Recurse:$chkRecurse.Checked)
    }
    if ($files.Count -eq 0) { Write-Log "No PDF files found."; return }

    New-Item -ItemType Directory -Path $out -Force | Out-Null
    $outRoot = (Resolve-Path -LiteralPath $out).Path.TrimEnd('\')
    $sameFolder = ($outRoot -eq $inRoot)

    $btnRun.Enabled = $false; $btnStop.Enabled = $true; $script:stopRequested = $false
    $progress.Minimum = 0; $progress.Maximum = $files.Count; $progress.Value = 0
    $log.Clear()
    Write-Log "qpdf: $qpdf"
    Write-Log "Input: $in  ($($files.Count) PDF file(s))"
    Write-Log "Output: $outRoot"
    if ($sameFolder) { Write-Log "Output = input folder, so '-decrypted' will be added to file names." }
    Write-Log ("-" * 70)

    $ok = 0; $warn = 0; $skipped = 0
    $failed = New-Object System.Collections.Generic.List[string]
    $pw = $txtPw.Text

    foreach ($f in $files) {
        if ($script:stopRequested) { Write-Log "Stopped by user."; break }

        $rel = $f.FullName.Substring($inRoot.Length).TrimStart('\')
        $dest = Join-Path $outRoot $rel
        if ($sameFolder) { $dest = Join-Path (Split-Path $dest) ($f.BaseName + "-decrypted" + $f.Extension) }
        New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null

        if ((Test-Path -LiteralPath $dest) -and -not $chkOverwrite.Checked) {
            Write-Log "SKIP    $rel  (output exists)"
            $skipped++
        } else {
            try {
                $r = Invoke-Qpdf $qpdf $f.FullName $dest $pw
                switch ($r.ExitCode) {
                    0 { Write-Log "OK      $rel"; $ok++ }
                    3 { Write-Log "WARN    $rel  -> $($r.Message)"; $warn++ }   # qpdf: output written, with warnings
                    default {
                        Write-Log "FAIL    $rel  -> $($r.Message)"
                        $failed.Add("$($f.FullName)`t$($r.Message)")
                        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue }
                    }
                }
            } catch {
                Write-Log "FAIL    $rel  -> $($_.Exception.Message)"
                $failed.Add("$($f.FullName)`t$($_.Exception.Message)")
            }
        }
        $progress.Value++
        $status.Text = "Processed $($progress.Value) of $($files.Count)"
        [System.Windows.Forms.Application]::DoEvents()
    }

    Write-Log ("-" * 70)
    Write-Log "Done. OK: $ok   Warnings: $warn   Skipped: $skipped   Failed: $($failed.Count)"

    if ($failed.Count -gt 0) {
        $failFile = Join-Path $outRoot ("qpdf_failed_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
        $header = @("qpdf failures - $(Get-Date)", "Input: $in", "File`tError", "")
        ($header + $failed) | Set-Content -LiteralPath $failFile -Encoding UTF8
        Write-Log "Failure list written to: $failFile"
    }
    $status.Text = "Done. OK: $ok  |  Warnings: $warn  |  Skipped: $skipped  |  Failed: $($failed.Count)"
    $btnRun.Enabled = $true; $btnStop.Enabled = $false
})

[void]$form.ShowDialog()
