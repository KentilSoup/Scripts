# -----------------------------------------------
# Time-Sync-Audit-v1.ps1
# Created By: Kent Fulton
# Last Edited: 09-30-2025
# -----------------------------------------------
# This PowerShell script audits time synchronization settings and logs on a Windows system.
# It performs the following tasks:
# - Queries NTP configuration using w32tm
# - Retrieves the polling interval from the registry
# - Checks current sync status via w32tm
# - Captures a recent timestamp from the Security event log
# The collected data is saved to a text file on the user's Desktop as TimeSyncAudit_Windows.txt.
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
