# -----------------------------------------------
# Export-PowerCLI-vCenter-Tags&Categories-Excel-v1.ps1
# Created By: Kent Fulton
# Last Edited: 11-07-2025
# -----------------------------------------------
# Description:
# This script connects to a specified vCenter server and exports vSphere tag 
# assignments and tag category metadata to an Excel file using the ImportExcel module.
# The output file is saved in the current user's Downloads folder and includes 
# two worksheets: "TagAssignments" and "TagCategories".
#
# Requirements:
# - PowerCLI must be installed and configured.
# - ImportExcel module must be installed: Install-Module -Name ImportExcel
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

# Define vCenter name
$vCenter = "***vCenter Name***"

# Use current user's Downloads folder
$downloadsPath = "$env:USERPROFILE\Downloads"
$excelFile = "$downloadsPath\${vCenter}_vSphere_Tags_$timestamp.xlsx"

# Connect to vCenter
Connect-VIServer -Server $vCenter

# Get tag assignments
$tagAssignments = Get-TagAssignment | Select-Object `
    @{Name='EntityName';Expression={$_.Entity.Name}},
    @{Name='EntityType';Expression={$_.Entity.GetType().Name}},
    @{Name='TagName';Expression={$_.Tag.Name}},
    @{Name='Category';Expression={$_.Tag.Category.Name}}

# Get tag categories
$tagCategories = Get-TagCategory | Select-Object Name, Cardinality, Description

# Create Excel file with two sheets using ImportExcel module
# Ensure ImportExcel module is installed: Install-Module -Name ImportExcel
$tagAssignments | Export-Excel -Path $excelFile -WorksheetName "TagAssignments" -AutoSize
$tagCategories | Export-Excel -Path $excelFile -WorksheetName "TagCategories" -AutoSize -Append

# Disconnect from vCenter
Disconnect-VIServer $vCenter -Confirm:$false

Write-Host "Export complete: $excelFile"
