# -----------------------------------------------
# Export-PowerCLI-vCenter-NonTaggedVMs-Excel-v1.ps1
# Created By: Kent Fulton
# Last Edited: 11-07-2025
# -----------------------------------------------
# This script connects to a specified vCenter server,
# retrieves VMs and other vSphere objects without tags,
# exports the results to an Excel file, and disconnects
# from the vCenter session.
# Requires: PowerCLI, ImportExcel modules
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

# Parameters
param (
    [string]$vCenter = "***vCenterName***",
    [string]$downloadsPath = "$env:USERPROFILE\Downloads"
)

# Timestamp for filename
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Connect to vCenter
Connect-VIServer -Server $vCenter

# Collect non-tagged VMs
$nonTaggedVMs = Get-VM | Where-Object {
    (Get-TagAssignment -Entity $_) -eq $null
} | Select-Object Name, PowerState, VMHost, @{Name="Cluster";Expression={($_ | Get-Cluster).Name}}

# You can expand this to include other object types if needed:
# $nonTaggedHosts = Get-VMHost | Where-Object { (Get-TagAssignment -Entity $_) -eq $null }

# Combine data (if needed)
$exportData = $nonTaggedVMs  # Add other collections here if needed

# Define Excel file path
$excelFile = "$downloadsPath\${vCenter}_NonTagged_Items_$timestamp.xlsx"

# Export to Excel
$exportData | Export-Excel -Path $excelFile -AutoSize -WorksheetName "NonTaggedItems"

# Disconnect from vCenter
Disconnect-VIServer -Server $vCenter -Confirm:$false

Write-Host "Export complete: $excelFile"
