# -----------------------------------------------
# Export-AD-Computers-v1.ps1
# Created By: Kent Fulton
# Last Edited: 09-30-2025
# -----------------------------------------------
# This PowerShell script queries Active Directory for all computer objects
# and collects selected properties: Name, OperatingSystem, ManagedBy, DNSHostName, and Description.
# It resolves the ManagedBy field to a readable name when available.
# Results are exported to an Excel file in the current user's profile directory.
# -----------------------------------------------

# If not already installed: Install-Module -Name ImportExcel -Scope CurrentUser

# Import required module
Import-Module ActiveDirectory

# Get all computers
$allComputers = Get-ADComputer -Filter * -Property Name, OperatingSystem, ManagedBy, DNSHostName, Description
$total = $allComputers.Count
$results = @()

# Loop with progress bar
for ($i = 0; $i -lt $total; $i++) {
    $comp = $allComputers[$i]

    Write-Progress -Activity "Processing AD Computers" -Status "Working on $($comp.Name)" -PercentComplete (($i / $total) * 100)

    $managedByName = "Not Set"
    if ($comp.ManagedBy) {
        try {
            $managedByName = (Get-ADObject -Identity $comp.ManagedBy -Properties Name).Name
        } catch {
            $managedByName = "Not Found"
        }
    }

    $results += [PSCustomObject]@{
        ComputerName    = $comp.Name
        OperatingSystem = $comp.OperatingSystem
        ManagedBy       = $managedByName
        DNSName         = $comp.DNSHostName
        Description     = $comp.Description
    }
}

# Export to Excel in current user's profile directory
$excelPath = "$env:USERPROFILE\Downloads\AD_Computers.xlsx"
$results | Export-Excel -Path $excelPath -AutoSize -WorksheetName "Computers"

Write-Host "✅ Export complete. File saved to: $excelPath"
