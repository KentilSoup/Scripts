# ------------------------------------------------------------
# Export-AD-Domain-All-Computers-Info-csv-v1.ps1
# Author: Kent Fulton
# Last Edited: 10-01-2025
# ------------------------------------------------------------
# This script exports computer information from the entire AD domain to Excel
# - Scans all computer objects in Active Directory
# - Collects the following attributes:
#     • Computer Name
#     • DNS Host Name
#     • Description
#     • Operating System
#     • Object Location (Distinguished Name)
#     • AD Managed By (resolved name if set)
#     • Last Logon Date (converted from raw timestamp)
# - Uses the ImportExcel module (no need for Excel to be installed)
# - Saves the output to the current user's Downloads folder
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

# Ensure ImportExcel module is available
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force
}

# Get current user's Downloads folder
$currentUser = $env:USERNAME
$downloadsPath = "C:\Users\$currentUser\Downloads"
$exportPath = Join-Path -Path $downloadsPath -ChildPath "AD_Computer_Export.xlsx"

# Get all computer objects in the domain
$computers = Get-ADComputer -Filter * -Properties Name, DNSHostName, Description, OperatingSystem, DistinguishedName, ManagedBy, LastLogonDate

# Prepare data for export
$exportData = foreach ($computer in $computers) {
    # Resolve ManagedBy name if set
    $managedByName = if ($computer.ManagedBy) {
        try {
            (Get-ADObject -Identity $computer.ManagedBy).Name
        } catch {
            "Lookup Failed"
        }
    } else {
        "Not Set"
    }

    # Format Last Logon Date
    $lastLogon = if ($computer.LastLogonDate) {
        $computer.LastLogonDate
    } else {
        "Never Logged On"
    }

    [PSCustomObject]@{
        "ComputerName"    = $computer.Name
        "DNSHostName"     = $computer.DNSHostName
        "Description"     = $computer.Description
        "OperatingSystem" = $computer.OperatingSystem
        "ObjectLocation"  = $computer.DistinguishedName
        "AD Managed By"   = $managedByName
        "Last Logon Date" = $lastLogon
    }
}

# Export to Excel
$exportData | Export-Excel -Path $exportPath -AutoSize -Title "AD Computer Export" -WorksheetName "Computers"

Write-Host "Export complete. File saved to $exportPath"
