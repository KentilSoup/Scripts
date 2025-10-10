# -----------------------------------------------
# Export-AD-Computers-TargetingOU-v1.ps1
# Created By: Kent Fulton
# Last Edited: 10-10-2025
# -----------------------------------------------
# This PowerShell script scans a specific Organizational Unit (OU) in Active Directory
# and collects the following attributes for each computer object:
# - Computer Name
# - DNS Host Name
# - Description
# - Operating System
# The results are exported to an Excel file in the current user's profile directory.
# Requires the ImportExcel module (Excel installation not required).
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

# Ensure ImportExcel module is available
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force
}

# Define the OU to scan (example path)
$OU = "OU=ExampleOU,DC=domain,DC=com"

# Get computer objects from the specified OU
$computers = Get-ADComputer -SearchBase $OU -SearchScope Subtree -Filter * -Properties Name, DNSHostName, Description, OperatingSystem

# Prepare data for export
$exportData = $computers | Select-Object `
    @{Name="ComputerName";Expression={$_.Name}},
    @{Name="DNSHostName";Expression={$_.DNSHostName}},
    @{Name="Description";Expression={$_.Description}},
    @{Name="OperatingSystem";Expression={$_.OperatingSystem}}

# Export to Excel in current user's profile directory
$exportPath = "$env:USERPROFILE\Downloads\AD_Computer_Export.xlsx"
$exportData | Export-Excel -Path $exportPath -AutoSize -Title "AD Computer Export" -WorksheetName "Computers"

Write-Host "✅ Export complete. File saved to: $exportPath"
