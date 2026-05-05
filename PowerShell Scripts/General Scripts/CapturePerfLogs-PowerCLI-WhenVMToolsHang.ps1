# -----------------------------------------------------------------
# CapturePerfLogs-PowerCLI-WhenVMToolsHang.ps1
# Created By: Kent Fulton
# Last Edited: 05-05-2026
# -----------------------------------------------------------------
# Purpose:
# Monitor VMware Tools for a recurring "tools service hung" condition.
# When detected, notify the administrator and automatically collect
# 15 minutes of detailed Windows performance data using an existing
# Logman performance counter collector (PerfLog-Short1) to aid in
# post-incident analysis and troubleshooting.
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
 
# Write that the service has hung and ping computer
Write-Host $svcHung
msg * /server:COMPUTERNAME "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - COMPUTERNAME - VMware Tools Service has entered a hung state!"

# The following is a script that creates a Windows Preformance Monitor data colletor using Logman
# (This is ran on the target computer for this script to function)
# Logman.exe create counter PerfLog-Short1 -o "C:\Example\COMPUTERNAME_PerfLog-Short1.blg" -f bincirc -v mmddhhmm -max 500 -c "\LogicalDisk(*)\*" "\Memory\*" "\.NET CLR Memory(*)\*" "\Cache\*" "\Network Interface(*)\*" "\Paging File(*)\*" "\PhysicalDisk(*)\*" "\Processor(*)\*" "\Processor Information(*)\*" "\Process(*)\*" "\Thread(*)\*" "\Redirector\*" "\Server\*" "\System\*" "\Server Work Queues(*)\*" "\Terminal Services\*" -si 00:00:01

# Start the performance counter collect
Logman.exe start PerfLog-Short1

# Let it run for 15 minutes (900 seconds)
Start-Sleep -Seconds 900

# Stop the performance counter collection
Logman.exe stop PerfLog-Short1
