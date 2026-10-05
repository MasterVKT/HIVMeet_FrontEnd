# run_emulator.ps1
# Launch Flutter on an Android emulator (auto-detected or specified via parameter).

param(
    [string]$targetDeviceId = $null
)

$projectRoot = 'D:\Projets\HIVMeet\hivmeet'
$logFile = Join-Path $projectRoot 'emulator_run.md'

# Resolve Flutter SDK: HIVMEET_FLUTTER_SDK override > canonical project SDK
# (Flutter 3.44.8 / Dart 3.12.2) > PATH fallback.
# An SDK is only accepted when its bundled Dart is >= 3.10 (google_fonts 8.x constraint),
# so a stale PATH pointing to an old Flutter (e.g. C:\flutter / Dart 3.6.1) is rejected.
function Get-CompatibleFlutterExe([string]$sdkRoot) {
    if (-not $sdkRoot) { return $null }
    $exe = Join-Path $sdkRoot 'bin\flutter.bat'
    if (-not (Test-Path -LiteralPath $exe)) { return $null }
    $vFile = Join-Path $sdkRoot 'bin\cache\dart-sdk\version'
    $dartVersion = if (Test-Path -LiteralPath $vFile) { (Get-Content $vFile -Raw).Trim() } else { '' }
    if ($dartVersion -match '^(\d+)\.(\d+)\.') {
        $major = [int]$Matches[1]; $minor = [int]$Matches[2]
        if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 10)) {
            Write-Warning "SDK incompatible (Dart $dartVersion < 3.10), ignore : $sdkRoot"
            return $null
        }
    }
    return $exe
}

$flutterExe = $null
if (-not [string]::IsNullOrWhiteSpace($env:HIVMEET_FLUTTER_SDK)) {
    $flutterExe = Get-CompatibleFlutterExe $env:HIVMEET_FLUTTER_SDK
}
if (-not $flutterExe) {
    $flutterExe = Get-CompatibleFlutterExe 'C:\Users\vekou\dev\flutter'
}
if (-not $flutterExe) {
    $cmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
    if ($cmd) { $flutterExe = Get-CompatibleFlutterExe (Split-Path (Split-Path $cmd.Source)) }
}

if (-not $flutterExe -or -not (Test-Path -LiteralPath $flutterExe)) {
    throw "Flutter SDK introuvable (Dart >= 3.10 requis)."
}

# Force UTF-8 everywhere
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Detect emulator device
$deviceId = $targetDeviceId
if (-not $deviceId) {
    $adbOutput = & adb devices 2>$null
    $emulators = @()
    if ($adbOutput) {
        foreach ($line in $adbOutput) {
            if ($line -match '^(emulator-\d+)\s+device$') {
                $emulators += $Matches[1]
            }
        }
    }

    if ($emulators.Count -eq 1) {
        $deviceId = $emulators[0]
    } elseif ($emulators.Count -gt 1) {
        # Check if emulator-5556 is present, otherwise fallback to first
        if ($emulators -contains 'emulator-5556') {
            $deviceId = 'emulator-5556'
        } else {
            $deviceId = $emulators[0]
        }
    } else {
        # Fallback to emulator-5554 if no active emulator matched
        $deviceId = 'emulator-5554'
    }
}

Write-Host "Chosen emulator device ID: $deviceId" -ForegroundColor Green

Set-Location $projectRoot

# Open log file with StreamWriter (UTF-8, single handle)
$writer = [System.IO.StreamWriter]::new($logFile, $false, [System.Text.UTF8Encoding]::new($true))

try {
    # Run flutter via cmd.exe with 2>&1 to merge stderr into stdout.
    # This avoids all PowerShell async event issues (Runspace, thread pool, dispatch).
    # Output is read synchronously on the main thread — simple and reliable.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c `"$flutterExe`" run -d $deviceId 2>&1"
    $psi.RedirectStandardOutput = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.UseShellExecute = $false
    $psi.WorkingDirectory = $projectRoot

    $process = [System.Diagnostics.Process]::Start($psi)

    # Synchronous read — Write-Host and $writer work on the main thread
    while (-not $process.StandardOutput.EndOfStream) {
        $line = $process.StandardOutput.ReadLine()
        if ($line -and $line -notmatch 'EGL_emulation') {
            Write-Host $line
            $writer.WriteLine($line)
            $writer.Flush()
        }
    }

    $process.WaitForExit()
} finally {
    $writer.Close()
}

Read-Host 'Press Enter to exit emulator run'

