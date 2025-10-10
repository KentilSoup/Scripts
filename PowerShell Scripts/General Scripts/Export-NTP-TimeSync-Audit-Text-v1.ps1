# -----------------------------------------------
# Export-NTP-TimeSync-Audit-Text-v1.ps1
# Created By: Kent Fulton
# Last Edited: 10-10-2025
# -----------------------------------------------
# This PowerShell script audits time synchronization settings and logs on a Windows system.
# It performs the following tasks:
# - Queries NTP configuration using w32tm
# - Retrieves the polling interval from the registry
# - Checks current sync status via w32tm
# - Captures a recent timestamp from the Security event log
# The collected data is saved to a text file on the user's Desktop as TimeSyncAudit_Windows.txt.
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

# Sets the PowerShell execution policy for the current session to RemoteSigned.
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

# Collects time sync configuration and audit timestamp evidence

$report = @()

# 1. NTP Configuration
$ntpConfig = w32tm /query /configuration
$report += "=== NTP Configuration ==="
$report += $ntpConfig

# 2. Polling Interval
$pollInterval = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient" | Select-Object -ExpandProperty SpecialPollInterval
$report += "`n=== Polling Interval (seconds) ==="
$report += $pollInterval

# 3. Sync Status
$syncStatus = w32tm /query /status
$report += "`n=== Sync Status ==="
$report += $syncStatus

# 4. Audit Timestamp Sample
$auditTime = Get-WinEvent -LogName Security -MaxEvents 1 | Select-Object TimeCreated
$report += "`n=== Audit Log Timestamp Sample ==="
$report += $auditTime.TimeCreated

# Save to file
$report | Out-File -FilePath "$env:USERPROFILE\Desktop\TimeSyncAudit_Windows.txt"
Write-Output "Report saved to Desktop as TimeSyncAudit_Windows.txt"
