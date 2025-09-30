# -----------------------------------------------
# Export-PowerCLI-vSphere-Inventory-And-AD-Data-csv-v1.ps1
# Created By: Kent Fulton
# Last Edited: 09-30-2025
# -----------------------------------------------
# This PowerShell script connects to multiple vCenters and retrieves VM inventory details.
# For each VM, it collects:
# - vCenter, cluster, host, OS version, tags, notes, and DNS name
# - Active Directory details: Computer Name, Managed By, and Object Path
# Results are exported to an Excel file in the current user's Downloads folder.
# Requires: VMware.PowerCLI, ImportExcel, and RSAT ActiveDirectory module.
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

# BEFORE RUNNING: Install-Module -Name ImportExcel -Scope CurrentUser

# Load required modules
Import-Module VMware.PowerCLI
Import-Module ImportExcel
Import-Module ActiveDirectory

# Example vCenters to connect to
$vCenters = @("vcenter01.example.com", "vcenter02.example.com", "vcenter03.example.com")

# Prompt for credentials
$cred = Get-Credential

# Initialize array to hold VM info
$vmData = @()

# Connect to each vCenter
foreach ($vc in $vCenters) {
    Write-Host "Connecting to $vc..."
    Connect-VIServer -Server $vc -Credential $cred

    $vms = Get-VM
    $totalVMs = $vms.Count
    $counter = 0

    foreach ($vm in $vms) {
        $counter++
        Write-Progress -Activity "Processing VMs" -Status "Processing $($vm.Name)" -PercentComplete (($counter / $totalVMs) * 100)

        $vmName = $vm.Name

        $dcObj = Get-Datacenter -VM $vm -ErrorAction SilentlyContinue
        $dcName = if ($dcObj) { $dcObj.Name } else { "Unknown Datacenter" }

        $tagAssignments = Get-TagAssignment -Entity $vm -ErrorAction SilentlyContinue
        $tagNames = if ($tagAssignments) {
            ($tagAssignments | ForEach-Object { $_.Tag.Name }) -join ", "
        } else {
            "No Tags"
        }

        $osVersion = $vm.Guest.OSFullName

        $clusterObj = $vm | Get-Cluster -ErrorAction SilentlyContinue
        $clusterName = if ($clusterObj) { $clusterObj.Name } else { "No Cluster" }

        $hostObj = $vm | Get-VMHost -ErrorAction SilentlyContinue
        $hostName = if ($hostObj) { $hostObj.Name } else { "No Host" }

        $dnsName = $vm.Guest.HostName
        $shortName = if ($dnsName) { $dnsName -replace "\.example\.com$", "" } else { $vmName }

        $adComputer = Get-ADComputer -Filter { Name -eq $shortName } -Properties ManagedBy, DistinguishedName -ErrorAction SilentlyContinue
        $adName = if ($adComputer) { $adComputer.Name } else { "Not Found in AD" }
        $adPath = if ($adComputer) { $adComputer.DistinguishedName } else { "No AD Path" }

        $adManagedByDN = if ($adComputer) { $adComputer.ManagedBy } else { $null }
        $adManagedByDisplay = if ($adManagedByDN) {
            $owner = Get-ADObject -Identity $adManagedByDN -Properties DisplayName -ErrorAction SilentlyContinue
            if ($owner -and $owner.DisplayName) { $owner.DisplayName } else { "No Owner" }
        } else {
            "No Owner"
        }

        $vmData += [PSCustomObject]@{
            vCenter              = $vc
            Datacenter           = $dcName
            Cluster              = $clusterName
            "Host of VM"         = $hostName
            VMName               = $vmName
            "DNS Name"           = $dnsName
            "OS Version"         = $osVersion
            Tags                 = $tagNames
            Notes                = $vm.ExtensionData.Config.Annotation
            "AD - Computer Name" = $adName
            "AD - Managed By"    = $adManagedByDisplay
            "AD - Object Path"   = $adPath
        }
    }

    Disconnect-VIServer -Server $vc -Confirm:$false
    Write-Host "Disconnected from $vc."
}

# Export to Excel in current user's Downloads folder
$exportPath = "$env:USERPROFILE\Downloads\vSphere-Inventory+AD.xlsx"
$vmData | Export-Excel -Path $exportPath -AutoSize -WorksheetName "VMs"

Write-Host "✅ Export complete. File saved to: $exportPath"
