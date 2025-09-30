# -----------------------------------------------
# Script Name: Ping-For-Active-Sessions-And-Shares-v5.ps1
# Created By: Kent Fulton
# Last Updated: 09-30-2025
# Purpose: Checks the status of a remote computer by:
#   1. Verifying if the computer is online via ping.
#   2. Displaying a progress bar while performing checks.
#   3. Querying active user sessions using QUser.
#   4. Retrieving SMB shares via Get-SmbShare.
#   5. Checking active SMB sessions via Get-SmbSession.
# Usage: Customize $computerName to target a specific machine.
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

$computerName = "Server1"

function Show-Loading {
    param (
        [string]$Message = "Loading",
        [int]$Seconds = 2
    )
    $steps = 20
    for ($i = 0; $i -le $steps; $i++) {
        $percent = ($i / $steps) * 100
        Write-Progress -Activity $Message -Status "$([math]::Round($percent))% Complete" -PercentComplete $percent
        Start-Sleep -Milliseconds ($Seconds * 1000 / $steps)
    }
    Write-Progress -Activity $Message -Completed
}

# Ping the computer
if (Test-Connection -ComputerName $computerName -Count 2 -Quiet) {
    Write-Host "$computerName is online and reachable.`n"

    Write-Host "Checking for active users..."
    Show-Loading -Message "Scanning for active users"

    try {
        $users = quser /server:$computerName 2>$null
        if ($users) {
            Write-Host "Active users on ${computerName}:`n"
            $users
        } else {
            Write-Host "No active users found. You still have access to the machine."
        }
    } catch {
        Write-Host "Failed to query users on $computerName. Error: $_"
    }

    Write-Host "`nChecking for SMB shares..."
    Show-Loading -Message "Scanning for SMB shares"

    try {
        $shares = Invoke-Command -ComputerName $computerName -ScriptBlock { Get-SmbShare } -ErrorAction Stop
        if ($shares) {
            Write-Host "SMB Shares on ${computerName}:`n"
            $shares | Format-Table Name, Path, Description -AutoSize
        } else {
            Write-Host "No SMB shares found or access denied."
        }
    } catch {
        Write-Host "Failed to retrieve SMB shares from $computerName. Error: $_"
    }

    Write-Host "`nChecking for active SMB sessions..."
    Show-Loading -Message "Scanning for SMB sessions"

    try {
        $sessions = Invoke-Command -ComputerName $computerName -ScriptBlock { Get-SmbSession } -ErrorAction Stop
        if ($sessions) {
            Write-Host "Active SMB sessions on ${computerName}:`n"
            $sessions | Format-Table ClientComputerName, ClientUserName, NumOpens -AutoSize
        } else {
            Write-Host "No active SMB sessions found."
        }
    } catch {
        Write-Host "Failed to retrieve SMB session info from $computerName. Error: $_"
    }

} else {
    Write-Host "$computerName is offline or unreachable."
}
