# ------------------------------------------------------------
# Update-AD-Computers-ManagedBy-csv-v1.ps1
# Created By: Kent Fulton
# Last Edited: 10-01-2025
# ------------------------------------------------------------
# CAUTION: THIS SCRIPT WRITES TO ACTIVE DIRECTORY!
# ------------------------------------------------------------
# Description:
# This script updates the 'ManagedBy' attribute of computer objects in Active Directory
# using data from a CSV file. It logs each change to a text file for auditing.
#
# CSV Requirements:
# - The input CSV must contain two columns:
#     • ComputerName — the name of the AD computer object
#     • ManagedBy    — the Distinguished Name (DN) of the user or group to assign
#
# Functionality:
# - Reads input CSV from C:\Users\_____\Downloads
# - Updates the 'ManagedBy' field in AD for each computer
# - Displays a live progress bar during execution
# - Logs old and new values with timestamps to a dated change log text file
# - Displays a completion message with log file location
# ------------------------------------------------------------
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
# ------------------------------------------------------------
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
# ------------------------------------------------------------

# Define static paths
$csvPath = "C:\Users\_____\Downloads\AD_ManagedBy_Update_Input.csv"
$dateStamp = Get-Date -Format "yyyy-MM-dd"
$logPath = "C:\Users\_____\Downloads\AD_ManagedBy_ChangeLog_$dateStamp.txt"

# Import the CSV data
$computers = Import-Csv -Path $csvPath

# Initialize log content
$logContent = @()
$logContent += "AD ManagedBy Update Log - $dateStamp"
$logContent += "------------------------------------------------------------"

# Initialize progress tracking
$total = $computers.Count
$counter = 0

# Loop through each entry in the CSV with progress bar
foreach ($entry in $computers) {
    $counter++
    $percentComplete = ($counter / $total) * 100

    Write-Progress -Activity "Updating AD 'ManagedBy' Attributes" `
                   -Status "Processing $counter of $total ($($entry.ComputerName))" `
                   -PercentComplete $percentComplete

    $computerName = $entry.ComputerName
    $newManagedBy = $entry.ManagedBy

    try {
        $adComputer = Get-ADComputer -Identity $computerName -Properties ManagedBy

        if ($adComputer) {
            $oldManagedBy = $adComputer.ManagedBy

            # Update the ManagedBy attribute
            Set-ADComputer -Identity $computerName -ManagedBy $newManagedBy

            # Log the change (fixed variable reference)
            $logContent += "[$(Get-Date)] ${computerName}: ManagedBy updated from '$oldManagedBy' to '$newManagedBy'"
        } else {
            $logContent += "[$(Get-Date)] WARNING: Computer '${computerName}' not found in AD."
        }
    } catch {
        $logContent += "[$(Get-Date)] ERROR: Failed to update '${computerName}'. $_"
    }
}

# Write log to file
$logContent | Out-File -FilePath $logPath -Encoding UTF8

# Notify completion
Write-Host "Update complete. Log saved to $logPath"
