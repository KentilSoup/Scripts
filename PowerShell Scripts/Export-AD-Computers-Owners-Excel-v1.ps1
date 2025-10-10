# -----------------------------------------------
# Export-AD-Computers-Owners-Excel-v1.ps1
# Created By: Kent Fulton
# Last Edited: 10-10-2025
# -----------------------------------------------
# This PowerShell script imports a list of server names from a CSV file,
# queries Active Directory for each server's description, OU location,
# and the name of the object listed in the ManagedBy field.
# Results are exported to a CSV file in the current user's profile directory.
# Failed lookups are logged with placeholder values.
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

# Import server names from a CSV file
$servers = Import-Csv -Path "$env:USERPROFILE\Downloads\ServerList.csv" | Select-Object -ExpandProperty ServerName

# Create an array to hold the results
$results = @()

foreach ($server in $servers) {
    try {
        $computer = Get-ADComputer -Identity $server -Properties Description, ManagedBy

        # Get the name of the ManagedBy object if it exists
        $managedByName = if ($computer.ManagedBy) {
            (Get-ADObject -Identity $computer.ManagedBy).Name
        } else {
            "Not Set"
        }

        # Get the OU path from the DistinguishedName
        $ouPath = ($computer.DistinguishedName -split ',CN=.*')[0]

        # Add the result to the array
        $results += [PSCustomObject]@{
            "Object Name" = $computer.Name
            "Managed By"  = $managedByName
            "Description" = $computer.Description
            "OU Location" = $ouPath
        }
    }
    catch {
        # Log the failure in the results
        $results += [PSCustomObject]@{
            "Object Name" = $server
            "Managed By"  = "Lookup Failed"
            "Description" = "Lookup Failed"
            "OU Location" = "Lookup Failed"
        }
    }
}

# Export to CSV in the current user's profile directory
$results | Export-Csv -Path "$env:USERPROFILE\Downloads\ComputerOwnerInfo.csv" -NoTypeInformation
