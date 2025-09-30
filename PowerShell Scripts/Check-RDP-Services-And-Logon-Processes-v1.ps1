# ================================================
# PowerShell Script: Check-RDP-Services-And-Logon-Processes-v1.ps1
# Author: Kent Fulton
# Last Edited: 09-30-2025
# Description:
#   - Verifies the status of key RDP-related services:
#       TermService, UmRdpService, SessionEnv, RpcSs, DcomLaunch, Netlogon
#   - Displays each service's:
#       - Name
#       - Current Status (Running, Stopped, etc.)
#       - Startup Type (Automatic, Manual, Disabled)
#   - Also checks for critical logon-related processes:
#       - lsass (Local Security Authority Subsystem Service)
#       - winlogon (Windows Logon Process)
#   - Useful for:
#       - Troubleshooting RDP connectivity issues
#       - Ensuring essential services and processes are running
#       - Quick health check of remote desktop infrastructure
# ================================================

# Check RDP-related services
$services = @(
    "TermService", "UmRdpService", "SessionEnv", "RpcSs", "DcomLaunch", "Netlogon"
)

Get-Service -Name $services | Select-Object Name, Status, StartType | Format-Table -AutoSize

# Check critical logon processes
Get-Process -Name lsass, winlogon | Select-Object Name, Id, StartTime
