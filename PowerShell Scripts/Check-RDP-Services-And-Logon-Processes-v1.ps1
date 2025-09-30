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

# Check RDP-related services
$services = @(
    "TermService", "UmRdpService", "SessionEnv", "RpcSs", "DcomLaunch", "Netlogon"
)

Get-Service -Name $services | Select-Object Name, Status, StartType | Format-Table -AutoSize

# Check critical logon processes
Get-Process -Name lsass, winlogon | Select-Object Name, Id, StartTime
