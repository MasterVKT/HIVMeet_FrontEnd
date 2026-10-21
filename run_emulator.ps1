# run_emulator.ps1
# Launch Flutter on an Android emulator (auto-detected or specified via parameter).

param(
    [string]$targetDeviceId = $null,
    # Target log file (defaults to emulator_run.md next to the script).
    [string]$LogFile = '',
    # Size cap (KB) of the active log file before it is rotated (0 = unlimited).
    [int]$MaxLogKB = 2048,
    # Number of rotated log backups kept next to the active file.
    [int]$MaxLogBackups = 3,
    # Keep Android logcat chatter (disable the noise filter).
    [switch]$NoFilter
)

$projectRoot = 'D:\Projets\HIVMeet\hivmeet'
$logFile = if ($LogFile) { $LogFile } else { Join-Path $projectRoot 'emulator_run.md' }

# Shared bounded, dual-output logging helper (see scripts/FlutterLogSession.ps1).
. (Join-Path $projectRoot 'scripts\FlutterLogSession.ps1')

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

# Bounded, dual-output log session: every kept line is echoed to the terminal
# AND appended to the log file, which is capped (MaxLogKB) and rotated into
# numbered backups (<stem>.1.md, <stem>.2.md, ...) to prevent astronomically
# large log files on long runs.
$logSession = New-FlutterLogSession -Path $logFile -MaxBytes ($MaxLogKB * 1KB) -MaxBackups $MaxLogBackups -NoFilter:$NoFilter

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

    # Synchronous read — Write-FlutterLogLine writes to both the terminal and
    # the rotating file on the main thread.
    while (-not $process.StandardOutput.EndOfStream) {
        $line = $process.StandardOutput.ReadLine()
        if ($line) {
            Write-FlutterLogLine -Session $logSession -Line $line
        }
    }

    $process.WaitForExit()
} finally {
    Close-FlutterLogSession -Session $logSession
    Write-FlutterLogSummary -Session $logSession
}

Read-Host 'Press Enter to exit emulator run'

