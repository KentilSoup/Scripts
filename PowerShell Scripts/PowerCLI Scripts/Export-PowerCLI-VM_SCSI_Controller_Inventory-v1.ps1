# -----------------------------------------------------------------
# Script Name: Export-PowerCLI-VM_SCSI_Controller_Inventory-v1.ps1
# Created By: Kent Fulton
# Last Edited: 01-21-2026
# -----------------------------------------------------------------
# Description:
# Connects to multiple vCenters, retrieves VM inventory details,
# and exports the results to a CSV file.
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

# List of vCenters to connect to
$vCenters = @(
    "vCenter1.domain.com",
    "vCenter2.domain.com",
    "vCenter3.domain.com",
    "vCenter4.domain.com",
    "vCenter5.domain.com"
)

# Connect to each vCenter
foreach ($vCenter in $vCenters) {
    Connect-VIServer -Server $vCenter
}

# Retrieve VM inventory
    # Name = VM name
    # PowerState = PoweredOn / PoweredOff / Suspended
    # IP Address = All guest IPs joined into one string
    # Guest OS = Full OS name reported by VMware Tools
    # vCPU Count = Number of virtual CPUs
    # SCSI Controllers = Controller type(s)
    # SCSI Controller Count = Number of SCSI controllers
    # PVSCSI / LSI SAS / LSI Parallel / BusLogic = per-type SCSI controller counts
    # vCenter = Extracted from VM UID
    # Disk Count = Number of virtual disks
    # Total Storage (GB) = Sum of all VM disks
    # Disk Map (bus:unit GB) = Per-disk list like "0:0 60, 0:1 200"

Get-VM | Select-Object `
    Name,
    PowerState,
    @{N="IP Address";E={($_.Guest.IPAddress -join ", ")}},
    @{N="Guest OS";E={$_.Guest.OSFullName}},
    @{N="vCPU Count";E={$_.NumCpu}},

    @{N="SCSI Controllers";E={
        $vc = $_.Uid.Split('@')[1].Split(':')[0]
        (Get-ScsiController -VM $_ -Server $vc | Select-Object -ExpandProperty Type) -join ", "
    }},
    @{N="SCSI Controller Count";E={
        $vc = $_.Uid.Split('@')[1].Split(':')[0]
        (Get-ScsiController -VM $_ -Server $vc).Count
    }},
    @{N="PVSCSI Count";E={
        $vc = $_.Uid.Split('@')[1].Split(':')[0]
        (Get-ScsiController -VM $_ -Server $vc | Where-Object {$_.Type -eq 'ParaVirtual'}).Count
    }},
    @{N="LSI SAS Count";E={
        $vc = $_.Uid.Split('@')[1].Split(':')[0]
        (Get-ScsiController -VM $_ -Server $vc | Where-Object {$_.Type -eq 'VirtualLsiLogicSAS'}).Count
    }},
    @{N="LSI Parallel Count";E={
        $vc = $_.Uid.Split('@')[1].Split(':')[0]
        (Get-ScsiController -VM $_ -Server $vc | Where-Object {$_.Type -eq 'VirtualLsiLogic'}).Count
    }},
    @{N="BusLogic Count";E={
        $vc = $_.Uid.Split('@')[1].Split(':')[0]
        (Get-ScsiController -VM $_ -Server $vc | Where-Object {$_.Type -eq 'VirtualBusLogic'}).Count
    }},

    @{N="vCenter";E={ $_.Uid.Split('@')[1].Split(':')[0] }},

    @{N="Disk Count";E={
        $vc = $_.Uid.Split('@')[1].Split(':')[0]
        (Get-HardDisk -VM $_ -Server $vc).Count
    }},

    @{N="Total Storage (GB)";E={
        $vc = $_.Uid.Split('@')[1].Split(':')[0]
        $sizes = Get-HardDisk -VM $_ -Server $vc | Select-Object -ExpandProperty CapacityGB
        if ($sizes) { [math]::Round(($sizes | Measure-Object -Sum).Sum,2) } else { 0 }
    }},

    @{N="Disk Map (bus:unit GB)";E={
        $vc = $_.Uid.Split('@')[1].Split(':')[0]
        $scsi = Get-ScsiController -VM $_ -Server $vc
        $keyToBus = @{}
        foreach ($c in $scsi) { $keyToBus[$c.ExtensionData.Key] = $c.ExtensionData.BusNumber }

        $disks = Get-HardDisk -VM $_ -Server $vc
        ($disks |
            Sort-Object -Property `
                @{Expression={$_.ExtensionData.ControllerKey}}, `
                @{Expression={$_.ExtensionData.UnitNumber}} |
            ForEach-Object {
                $ck   = $_.ExtensionData.ControllerKey
                $unit = $_.ExtensionData.UnitNumber
                $bus  = $keyToBus[$ck]
                $size = [math]::Round($_.CapacityGB,2)
                if ($null -ne $bus -and $null -ne $unit) { "{0}:{1} {2}" -f $bus, $unit, $size }
                else { "{0}" -f $size }
            }
        ) -join ", "
    }} |
Export-Csv -Path "C:\Users\username\Downloads\VM_SCSI_Controller_Report.csv" -NoTypeInformation
