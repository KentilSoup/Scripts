# -----------------------------------------------
# Collect-VMToolsHang-DumpAndPerf-v1.ps1
# Created By: Kent Fulton
# Last Edited: 12-24-2025
# -----------------------------------------------
# Purpose:
# - Prepare a dump folder
# - Restart VMware Tools and clear the tools log
# - Monitor the tools log for "tools service hung"
# - When detected, capture a full memory dump of the VMTools service
# - Then run Get-psSDP.ps1 with "perf" to collect performance diagnostics
# Run As: PowerShell (Admin), not PowerShell ISE
# -----------------------------------------------
# Setup:
# 1. Download Sysinternals ProcDump and place it in: C:\Tools\Sysinternals
#    https://learn.microsoft.com/en-us/sysinternals/downloads/procdump
# 2. Edit tools.conf at: C:\ProgramData\VMware\VMware Tools\tools.conf
#    Set logging section to:
#       [logging]
#       log = true
#       vmsvc.level = info
# 3. Run this script in an elevated PowerShell console (NOT ISE).
# 4. After the script exits, find the dump file in: C:\Dumps
# -----------------------------------------------
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
# -----------------------------------------------
# This script is provided "as-is" without any warranties, guarantees,
# or assurances of any kind. Use of this script is at your own risk.
#
# The author assumes no responsibility or liability for any direct,
# indirect, incidental, consequential, or punitive damages resulting
# from the use, misuse, or inability to use this script.
#
# It is the user's responsibility to review, test, and validate the
# script in a safe environment before deploying it in production.
#
# By using this script, you acknowledge that you understand and accept
# these terms. If you do not agree, do not use this script.
# -----------------------------------------------

# Create dump folder (no error if it already exists)
New-Item -Path "C:\Dumps" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

# Restart VMware Tools and clear the previous log
Stop-Service -Name VMTools
Start-Sleep -Seconds 3
Remove-Item -Path "C:\Windows\Temp\vmware-vmsvc-SYSTEM.log"
Start-Service -Name VMTools

# Get VMware Tools service PID (used for the dump)
Start-Sleep -Seconds 1
$svcPid = (Get-CimInstance -ClassName Win32_Service -Filter "Name = 'VMTools'").ProcessId

# Initialize a variable to hold the matched hang line
$svcHung = $null

# Tail the tools log and wait until "tools service hung" appears
do {
   Start-Sleep -Seconds 1
   $svcHung = Get-Content -Path "C:\Windows\Temp\vmware-vmsvc-SYSTEM.log" -Wait | Where-Object { $_ -match "tools service hung" } | Select-Object -First 1
} until ($svcHung)

# Echo the matching hang line to the console
Write-Host $svcHung

# Capture a full memory dump of the VMTools process to C:\Dumps
C:\Tools\Sysinternals\procdump -accepteula -ma $svcPid C:\Dumps\

# Run psSDP performance collection
& "C:\TSS\psSDP\Get-psSDP.ps1" perf
