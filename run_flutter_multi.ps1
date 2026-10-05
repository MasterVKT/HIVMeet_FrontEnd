# run_flutter_multi.ps1
# Launches two separate PowerShell windows:
# 1. Android emulator
# 2. Physical device
# The script uses the project root to ensure flutter finds pubspec.yaml.

$projectRoot = 'D:\\Projets\\HIVMeet\\hivmeet'
# Resolve full script paths using $projectRoot
$emuScript  = Join-Path $projectRoot 'run_emulator.ps1'
$devScript  = Join-Path $projectRoot 'run_device.ps1'

# Verify scripts exist before starting
if (!(Test-Path $emuScript)) {
	Write-Host "Error: $emuScript not found. Make sure it exists."
	exit 1
}
if (!(Test-Path $devScript)) {
	Write-Host "Error: $devScript not found. Make sure it exists."
	exit 1
}

# Start each script in its own PowerShell window and keep them open
# Launch each script in its own PowerShell window.  The ``-NoExit`` flag
# keeps the window open after the script completes so you can see the logs.
Start-Process powershell.exe -ArgumentList '-NoExit', '-File', $emuScript
Start-Process powershell.exe -ArgumentList '-NoExit', '-File', $devScript
