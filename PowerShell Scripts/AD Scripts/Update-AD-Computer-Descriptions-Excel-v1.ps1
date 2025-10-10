# -----------------------------------------------
# Update-AD-Computer-Descriptions-Excel-v1.ps1
# Created By: Kent Fulton
# Last Edited: 10-10-2025
# -----------------------------------------------
# WARNING: This script performs critical operations. Test thoroughly before use.
# This PowerShell script reads a CSV file containing computer names and new descriptions,
# then updates the Description field in Active Directory if changes are detected.
# It performs the following tasks:
# - Imports a CSV with columns: ComputerName and Description
# - Skips rows with missing or empty ComputerName values
# - Compares current AD description with the new one
# - Updates only if the description is different
# - Logs all actions (updates, skips, errors, not found) to a timestamped log file
# - Provides color-coded console output for visibility
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

# Import the Active Directory module
Import-Module ActiveDirectory

# Path to your CSV file
$csvPath = "$env:USERPROFILE\Desktop\ComputerName&Descriptions.csv"

# Path to your log file
$logPath = "$env:USERPROFILE\Desktop\AD_Update_Log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"

# Import the CSV
$computers = Import-Csv -Path $csvPath

# Start logging
Add-Content -Path $logPath -Value "`n--- Script Run: $(Get-Date) ---`n"

foreach ($entry in $computers) {
    $name = $entry.ComputerName
    $newDescription = $entry.Description

    # Skip if ComputerName is null or empty
    if ([string]::IsNullOrWhiteSpace($name)) {
        $log = "[$(Get-Date)] Skipped row with empty ComputerName."
        Write-Warning $log
        Add-Content -Path $logPath -Value $log
        continue
    }

    # Get the computer object from AD
    $computer = Get-ADComputer -Identity $name -Properties Description -ErrorAction SilentlyContinue
    if ($null -eq $computer) {
        $log = "[$(Get-Date)] Computer '$name' not found in AD."
        Write-Warning $log
        Add-Content -Path $logPath -Value $log
        continue
    }

    # Only update if the description is different
    if ($computer.Description -ne $newDescription) {
        try {
            Set-ADComputer -Identity $name -Description $newDescription
            $log = "[$(Get-Date)] Updated '$name' description to '$newDescription'"
            Write-Host $log -ForegroundColor Green
        } catch {
            $log = "[$(Get-Date)] ERROR updating '$name': $_"
            Write-Error $log
        }
    } else {
        $log = "[$(Get-Date)] No change needed for '$name'"
        Write-Host $log -ForegroundColor Yellow
    }

    # Write log entry
    Add-Content -Path $logPath -Value $log
}
