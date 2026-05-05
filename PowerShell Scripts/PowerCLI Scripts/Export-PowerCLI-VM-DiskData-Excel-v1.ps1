# =====================================================
# NAME: Export-PowerCLI-VM-DiskData-Excel-v1.ps1
# CREATED BY: Kent Fulton
# LAST MODIFIED: 2026-05-05
#
# DESCRIPTION:
# Collects and outputs disk data from:
# - vSphere (PowerCLI)
# - Windows guest OS (via VMware Tools)
#
# OUTPUT:
# - vSphere disk layout
# - Windows disk layout
# - TXT audit report saved to Downloads
#
# REQUIREMENTS:
# - VMware PowerCLI
# - Access to vCenter
# - VMware Tools installed on VM
# - Valid Windows credentials for guest access
# =====================================================
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
# =====================================================
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
# =====================================================

clear

# Enter target VMs Name:

$VMName = "VM NAME"

# Enter target vCenter which VM resides on:

Connect-VIServer -Server "vCenter.domain.com"

$vm = Get-VM -Name $VMName -ErrorAction SilentlyContinue

if (-not $vm) {
    Write-Host "VM not found: $VMName" -ForegroundColor Red
    exit
}

# =====================================================
# SECTION 1 - vSphere DISK VIEW
# =====================================================

Write-Host ""
Write-Host "===== vSphere Disk Layout =====`n" -ForegroundColor Cyan

$controllers = Get-ScsiController -VM $vm | ForEach-Object {
    [PSCustomObject]@{
        Key   = $_.ExtensionData.Key
        Index = $_.ExtensionData.BusNumber
        Type  = $_.Type
    }
}

$vSphere = foreach ($disk in Get-HardDisk -VM $vm) {

    $ctrl = $controllers | Where-Object { $_.Key -eq $disk.ExtensionData.ControllerKey }

    # FIX #1: safe fallback if controller not found
    if (-not $ctrl) {
        $controllerIndex = "?"
        $controllerType  = "Unknown"
    }
    else {
        $controllerIndex = $ctrl.Index
        $controllerType  = $ctrl.Type
    }

    $unitNumber = $disk.ExtensionData.UnitNumber
    $scsi = "$controllerIndex`:$unitNumber"

    $sizeGB = [math]::Round($disk.CapacityGB,0)

    [PSCustomObject]@{
        VM              = $vm.Name
        DiskName        = $disk.Name
        SCSI            = $scsi
        ControllerType  = $controllerType
        ControllerIndex = $controllerIndex
        UnitNumber      = $unitNumber
        SizeGB          = $sizeGB
        Provisioning    = if ($disk.StorageFormat) { $disk.StorageFormat } else { "Unknown" }
        DiskUUID        = $disk.ExtensionData.Backing.Uuid
        VMDK            = $disk.Filename
        CompareKey      = "$($vm.Name)-$controllerIndex-$unitNumber-$sizeGB"
    }
}

# --- vSphere OUTPUT ---
$vSphere |
    Sort-Object SCSI |
    Format-Table -AutoSize | Out-String -Width 4096

# =====================================================
# SECTION 2 - WINDOWS DISK VIEW
# =====================================================

Write-Host "`n===== Windows Disk Layout =====`n" -ForegroundColor Cyan

$cred = Get-Credential -Message "Enter Windows credentials for VM access"

$script = @'
$disks = Get-Disk | Where-Object { $_.Number -ge 0 }

$result = foreach ($d in $disks) {

    $parts = Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue
    $volumes = foreach ($p in $parts) {
        Get-Volume -Partition $p -ErrorAction SilentlyContinue
    }

    $letters = $parts | Where-Object DriveLetter | Select-Object -ExpandProperty DriveLetter
    $volName = ($volumes | Where-Object FileSystemLabel | Select-Object -ExpandProperty FileSystemLabel -First 1)

    # FIX #3: safe free space handling
    $free = ($volumes | Measure-Object -Property SizeRemaining -Sum).Sum
    if (-not $free) { $free = 0 }

    $freeGB = [math]::Round($free / 1GB,0)
    $sizeGB = [math]::Round($d.Size / 1GB,0)

    [PSCustomObject]@{
        VM            = $env:COMPUTERNAME
        Health        = $d.OperationalStatus
        DiskNumber    = $d.Number
        DriveLetters  = ($letters -join ",")
        DiskName      = $volName
        Type          = $d.BusType
        Layout        = $d.PartitionStyle
        SizeGB        = $sizeGB
        FreeGB        = $freeGB
        UsedGB        = ($sizeGB - $freeGB)
        CompareKey    = "$($env:COMPUTERNAME)-$($d.Number)-$sizeGB"
    }
}

$result | Sort-Object DiskNumber | Format-Table -AutoSize
'@

try {
    $raw = Invoke-VMScript -VM $vm `
        -ScriptText $script `
        -GuestCredential $cred `
        -ScriptType PowerShell

    # WINDOWS OUTPUT
    $raw.ScriptOutput
}
catch {
    Write-Host "FAILED: Windows disk query failed (VMware Tools or credentials issue)" -ForegroundColor Red
    exit
}

# =====================================================
# SECTION 3 - TXT EXPORT
# =====================================================

$timestampDisplay = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$timestampFile    = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$createdBy = $env:USERNAME
$datacenter = (Get-Datacenter -VM $vm).Name

$exportPath = "$env:USERPROFILE\Downloads\DiskInfo-$VMName-$timestampFile.txt"

$txt = @()

$txt += "===== DISK AUDIT REPORT ====="
$txt += ""
$txt += "Created By   : $createdBy"
$txt += "Created Date : $timestampDisplay"
$txt += "Datacenter   : $datacenter"
$txt += "VM Name      : $VMName"
$txt += ""

$txt += "===== vSphere Disk Layout =====`n"
$txt += ($vSphere | Sort-Object SCSI | Format-Table -AutoSize | Out-String)

$txt += "`n===== Windows Disk Layout =====`n"
$txt += $raw.ScriptOutput

$txt | Out-File -FilePath $exportPath -Encoding UTF8

Write-Host "`nThis has been saved to $exportPath" -ForegroundColor Green
