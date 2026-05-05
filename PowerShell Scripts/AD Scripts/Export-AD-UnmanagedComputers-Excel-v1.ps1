# -----------------------------------------------------------------
# Export-AD-UnmanagedComputers-Excel-v1.ps1
# Created By: Kent Fulton
# Last Edited: 11-07-2025
# -----------------------------------------------------------------
# Description:
# This script queries Active Directory for all computer objects
# and lists those that do not have a 'ManagedBy' attribute set.
# It includes OS Name, OU Location, and Description.
# Results are exported to a CSV file in the user's Downloads folder.
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

Import-Module ActiveDirectory

# Define export path
$downloadsPath = "$env:USERPROFILE\Downloads"
$exportFile = Join-Path -Path $downloadsPath -ChildPath "AD_UnmanagedComputers_Details.csv"

# Get all computer objects with relevant properties
$computers = Get-ADComputer -Filter * -Properties ManagedBy, OperatingSystem, Description

# Filter for computers with no ManagedBy value
$unmanagedComputers = $computers | Where-Object { -not $_.ManagedBy }

# Initialize progress bar
$total = $unmanagedComputers.Count
$counter = 0
$results = @()

foreach ($computer in $unmanagedComputers) {
    $counter++
    Write-Progress -Activity "Processing unmanaged computers..." `
                   -Status "Working on $($computer.Name)" `
                   -PercentComplete (($counter / $total) * 100)

    $results += [PSCustomObject]@{
        Name            = $computer.Name
        OperatingSystem = $computer.OperatingSystem
        OU              = ($computer.DistinguishedName -replace '^CN=.*?,', '')
        Description     = $computer.Description
    }
}

# Export results to CSV
$results | Export-Csv -Path $exportFile -NoTypeInformation

Write-Host "`nExport complete. File saved to: $exportFile"
