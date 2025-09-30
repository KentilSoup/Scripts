
# ================================================
# PowerShell Script: Export-EventLog-Reboots-ServiceLogs-ServiceFailures-v1.ps1
# Author: Kent Fulton
# Last Edited: 09-30-2025
# Description:
#   - Collects and exports system event logs from the past 7 days.
#   - Includes:
#       1. System reboot events (shutdowns, startups, unexpected shutdowns)
#       2. Service state changes for key RDP-related services
#       3. Service failures, timeouts, and dependency issues
#   - Outputs are saved as CSV files on the user's Desktop.
# ================================================
# DISCLAIMER
# ================================================
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
# ================================================

# Define time range
$startTime = (Get-Date).AddDays(-7)
$endTime = Get-Date

# Output file paths
$rebootLog = "$env:USERPROFILE\Desktop\SystemReboots_Last7Days.csv"
$serviceLog = "$env:USERPROFILE\Desktop\RDPServiceEvents_Last7Days.csv"
$failureLog = "$env:USERPROFILE\Desktop\ServiceFailures_Last7Days.csv"

# --- 1. Get System Reboots ---
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Id = 6006, 6005, 6008  # Shutdown, startup, unexpected shutdown
    StartTime = $startTime
    EndTime = $endTime
} | Select-Object TimeCreated, Id, Message |
Export-Csv -Path $rebootLog -NoTypeInformation

# --- 2. Get Service Events for RDP-related services ---
$services = @("Netlogon", "UMRdpService", "TermService", "RpcSs", "DcomLaunch")

Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Service Control Manager'
    Id = 7036  # Service state change
    StartTime = $startTime
    EndTime = $endTime
} | Where-Object {
    $msg = $_.Message
    $services | Where-Object { $msg -like "*$_*" }
} | Select-Object TimeCreated, Message |
Export-Csv -Path $serviceLog -NoTypeInformation

# --- 3. Get Service Failures and Timeouts ---
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Service Control Manager'
    Id = 7000, 7001, 7011, 7022  # Failures, dependency issues, timeouts
    StartTime = $startTime
    EndTime = $endTime
} | Select-Object TimeCreated, Id, Message |
Export-Csv -Path $failureLog -NoTypeInformation

Write-Host "✅ Export complete."
Write-Host "System reboots saved to: $rebootLog"
Write-Host "Service events saved to: $serviceLog"
Write-Host "Service failures saved to: $failureLog"
