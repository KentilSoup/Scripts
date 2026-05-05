# -----------------------------------------------------------------
# CaptureSnapshot-PowerCLI-WhenVMToolsHangs.ps1
# Created By: Kent Fulton
# Last Edited: 05-05-2026
# -----------------------------------------------------------------
# Purpose:
# Connects to vCenter, restarts VMware Tools, clears the Tools log,
# then tails the log in real time. When "tools service hung" appears,
# the script captures a memory snapshot of the VM and prints the line.
# -----------------------------------------------------------------
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
# -----------------------------------------------------------------
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
# -----------------------------------------------------------------

# Install-Module -Name VMware.PowerCLI -Scope CurrentUser

# Connect to vCenter for executing powercli commands
Connect-VIServer -Server vCenter.domain.com
 
# Restart VMware Tools and clear the previous log
Stop-Service -Name VMTools
Start-Sleep -Seconds 3
Remove-Item -Path "C:\Windows\Temp\vmware-vmsvc-SYSTEM.log"
Start-Service -Name VMTools
 
# Initialize a variable to hold the matched hang line
$svcHung = $null
 
# Tail the tools log and wait until "tools service hung" appears
do {
   Start-Sleep -Seconds 1
   $svcHung = Get-Content -Path "C:\Windows\Temp\vmware-vmsvc-SYSTEM.log" -Tail 0 -Wait -ReadCount 1| Where-Object { $_ -match "tools service hung" } | Select-Object -First 1
} until ($svcHung)
 
# Capture VM snapshot and memory + Echo the matching hang line to the console
New-Snapshot -VM "TARGET-VM-NAME" -Name "MemorySnapshot" -Memory
Write-Host $svcHung

msg * /server:COMPUTER-NAME-TO-RECIVE-ALERT "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - VMware Tools Service has entered a hung state!"
