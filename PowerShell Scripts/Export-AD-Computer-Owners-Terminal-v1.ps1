# -----------------------------------------------
# Export-AD-Computer-Owners-Terminal-v1.ps1
# Created By: Kent Fulton
# Last Edited: 09-30-2025
# -----------------------------------------------
# This PowerShell script imports a list of server names from a CSV file,
# queries Active Directory for each server's description, OU location,
# and the name of the object listed in the ManagedBy field.
# Results are printed directly to the terminal for quick review.
# Failed lookups are displayed with placeholder values.
# -----------------------------------------------

# Import server names from a CSV file
$servers = Import-Csv -Path "$env:USERPROFILE\Downloads\ServerList.csv" | Select-Object -ExpandProperty ServerName

foreach ($server in $servers) {
    try {
        $computer = Get-ADComputer -Identity $server -Properties Description, ManagedBy

        $managedByName = if ($computer.ManagedBy) {
            (Get-ADObject -Identity $computer.ManagedBy).Name
        } else {
            "Not Set"
        }

        $ouPath = ($computer.DistinguishedName -split ',CN=.*')[0]

        Write-Host "`n--- $server ---"
        Write-Host "Object Name : $($computer.Name)"
        Write-Host "Managed By  : $managedByName"
        Write-Host "Description : $($computer.Description)"
        Write-Host "OU Location : $ouPath"
    }
    catch {
        Write-Host "`n--- $server ---"
        Write-Host "Object Name : $server"
        Write-Host "Managed By  : Lookup Failed"
        Write-Host "Description : Lookup Failed"
        Write-Host "OU Location : Lookup Failed"
    }
}
