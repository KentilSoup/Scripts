# -----------------------------------------------------------------
# vCenter-CL-VMCustomSpecs-Templates-Report.ps1
# Created By: Kent Fulton
# Last Edited: 06-09-2026
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
<#
.SYNOPSIS
Connects to a list of vCenters and exports inventory data to a single Excel workbook.

.DESCRIPTION
This read-only script connects to a list of vCenters and exports:
1. Content Library inventory
2. VM Customization Specifications
3. VM Templates

The script exports the data to one Excel workbook with three worksheets:
- ContentLibrary
- CustomSpecs
- Templates

This script is read-only and uses only Get-* cmdlets and CIS/REST read operations
(list/get) against vCenter.

.REQUIREMENTS
- VCF.PowerCLI (preferred) or VMware.PowerCLI
- ImportExcel
#>
# -----------------------------------------------------------------

# -----------------------------
# Hard-coded vCenter list
# -----------------------------
$vCenters = @(

    'vCenter1.domain.com'
    'vCenter2.domain.com'
    'vCenter3.domain.com'
)

# -----------------------------
# Prompt for credentials
# -----------------------------
$Credential = Get-Credential -Message 'Enter vCenter credentials'

# -----------------------------
# Load PowerCLI module
# -----------------------------
Write-Host "Loading PowerCLI module..." -ForegroundColor Cyan

if (Get-Module -ListAvailable -Name VCF.PowerCLI) {
    Import-Module VCF.PowerCLI -ErrorAction Stop
}
elseif (Get-Module -ListAvailable -Name VMware.PowerCLI) {
    Import-Module VMware.PowerCLI -ErrorAction Stop
}
else {
    throw "Neither VCF.PowerCLI nor VMware.PowerCLI is installed."
}

# Ensure CIS cmdlets are available
if (-not (Get-Command Connect-CisServer -ErrorAction SilentlyContinue)) {
    if (Get-Module -ListAvailable -Name VMware.VimAutomation.Cis.Core) {
        Import-Module VMware.VimAutomation.Cis.Core -ErrorAction Stop
    }
    else {
        throw "Connect-CisServer / Get-CisService cmdlets are not available. Ensure VMware.VimAutomation.Cis.Core is installed."
    }
}

# -----------------------------
# Load ImportExcel
# -----------------------------
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    throw "ImportExcel module is not installed. Run: Install-Module ImportExcel -Scope CurrentUser"
}

Import-Module ImportExcel -ErrorAction Stop

# -----------------------------
# PowerCLI session settings
# -----------------------------
Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -ParticipateInCEIP:$false -Confirm:$false | Out-Null

# -----------------------------
# Output file
# -----------------------------
$timeStamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
$OutputFile = "C:\Temp\vCenter-CL-VMCustomSpecs-Templates-Report_$timeStamp.xlsx"

# Ensure output folder exists
$OutputFolder = Split-Path $OutputFile -Parent
if (-not (Test-Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# -----------------------------
# Helper functions
# -----------------------------
function Get-NestedPropertyValue {
    param (
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)] [string[]] $PropertyPaths
    )

    foreach ($path in $PropertyPaths) {
        $current = $Object
        $found   = $true

        foreach ($segment in ($path -split '\.')) {
            if ($null -eq $current) {
                $found = $false
                break
            }

            $prop = $current.PSObject.Properties[$segment]
            if (-not $prop) {
                $found = $false
                break
            }

            $current = $prop.Value
        }

        if ($found -and $null -ne $current -and "$current" -ne '') {
            return $current
        }
    }

    return $null
}

function Convert-ToDisplayString {
    param (
        [Parameter(ValueFromPipeline = $true)] $Value
    )

    if ($null -eq $Value) {
        return ''
    }

    if ($Value -is [System.Array]) {
        return (($Value | Where-Object { $null -ne $_ -and "$_" -ne '' }) | ForEach-Object { "$_" }) -join '; '
    }

    return "$Value"
}

function Format-DecimalString {
    param (
        [Parameter(Mandatory = $false)] [decimal] $Value,
        [Parameter(Mandatory = $false)] [string] $Suffix = ''
    )

    if ($null -eq $Value) {
        return ''
    }

    if ($Suffix) {
        return ('{0:N2} {1}' -f $Value, $Suffix)
    }

    return ('{0:N2}' -f $Value)
}

function Convert-BoolToYesNo {
    param (
        [Parameter(Mandatory = $false)] $Value
    )

    if ($null -eq $Value -or "$Value" -eq '') {
        return ''
    }

    if ($Value -is [bool]) {
        if ($Value) { return 'Yes' }
        return 'No'
    }

    switch -Regex ("$Value") {
        '^(true)$'  { return 'Yes' }
        '^(false)$' { return 'No'  }
        default     { return "$Value" }
    }
}

function Get-CisIdentifierValue {
    param (
        [Parameter(Mandatory = $true)] $Identifier
    )

    if ($null -eq $Identifier) {
        return $null
    }

    if ($Identifier -is [string]) {
        return $Identifier
    }

    if ($Identifier.PSObject.Properties['Value'] -and $Identifier.Value) {
        return $Identifier.Value
    }

    if ($Identifier.PSObject.Properties['value'] -and $Identifier.value) {
        return $Identifier.value
    }

    return "$Identifier"
}

function Get-CustomizationNamingInfo {
    param (
        [Parameter(Mandatory = $false)] $NamingObject
    )

    $result = [ordered]@{
        Scheme = ''
        Prefix = ''
    }

    if ($null -eq $NamingObject) {
        return [PSCustomObject]$result
    }

    $typeName = $NamingObject.GetType().Name

    switch ($typeName) {
        'CustomizationFixedName' {
            $result.Scheme = 'FixedName'
            if ($NamingObject.PSObject.Properties['Name'] -and $NamingObject.Name) {
                $result.Prefix = $NamingObject.Name
            }
        }
        'CustomizationPrefixName' {
            $result.Scheme = 'Prefix'
            if ($NamingObject.PSObject.Properties['Base'] -and $NamingObject.Base) {
                $result.Prefix = $NamingObject.Base
            }
        }
        'CustomizationVirtualMachineName' {
            $result.Scheme = 'Vm'
        }
        'CustomizationUnknownName' {
            $result.Scheme = 'Unknown'
        }
        default {
            $result.Scheme = $typeName
        }
    }

    return [PSCustomObject]$result
}

function Get-CustomizationNicSummary {
    param (
        [Parameter(Mandatory = $false)] $NicMappings
    )

    if (-not $NicMappings) {
        return ''
    }

    $nicSummaryList = @()
    $index = 1

    foreach ($nic in $NicMappings) {
        $parts = @()

        $ipMode = Get-NestedPropertyValue -Object $nic -PropertyPaths @(
            'IpMode',
            'ExtensionData.Adapter.Ip.IpAddress',
            'ExtensionData.Adapter.Ip'
        )

        $ipAddress = Get-NestedPropertyValue -Object $nic -PropertyPaths @(
            'IpAddress',
            'ExtensionData.Adapter.Ip.IpAddress'
        )

        $subnetMask = Get-NestedPropertyValue -Object $nic -PropertyPaths @(
            'SubnetMask',
            'ExtensionData.Adapter.SubnetMask'
        )

        $gateway = Get-NestedPropertyValue -Object $nic -PropertyPaths @(
            'DefaultGateway',
            'ExtensionData.Adapter.Gateway'
        )

        $dns = Get-NestedPropertyValue -Object $nic -PropertyPaths @(
            'Dns',
            'ExtensionData.Adapter.DnsServerList'
        )

        $wins = Get-NestedPropertyValue -Object $nic -PropertyPaths @(
            'Wins',
            'ExtensionData.Adapter.WinsServerList'
        )

        if ($ipMode)     { $parts += "Mode=$ipMode" }
        if ($ipAddress)  { $parts += "IP=$ipAddress" }
        if ($subnetMask) { $parts += "Mask=$subnetMask" }
        if ($gateway)    { $parts += "GW=$(Convert-ToDisplayString $gateway)" }
        if ($dns)        { $parts += "DNS=$(Convert-ToDisplayString $dns)" }
        if ($wins)       { $parts += "WINS=$(Convert-ToDisplayString $wins)" }

        if (-not $parts) {
            $parts += 'No NIC detail'
        }

        $nicSummaryList += "NIC${index}: $($parts -join ', ')"
        $index++
    }

    return ($nicSummaryList -join ' | ')
}

function Get-vSphereFolderPath {
    param (
        [Parameter(Mandatory = $false)] $ParentMoRef,
        [Parameter(Mandatory = $true)] $Server,
        [Parameter(Mandatory = $true)] [hashtable] $ViewCache
    )

    if ($null -eq $ParentMoRef) {
        return ''
    }

    $segments       = @()
    $currentRef     = $ParentMoRef
    $reachedVmRoot  = $false

    while ($currentRef) {
        $cacheKey = "$($currentRef.Type):$($currentRef.Value)"

        if (-not $ViewCache.ContainsKey($cacheKey)) {
            $ViewCache[$cacheKey] = Get-View -Id $currentRef -Property Name,Parent -Server $Server -ErrorAction SilentlyContinue
        }

        $currentView = $ViewCache[$cacheKey]

        if (-not $currentView) {
            break
        }

        if ($currentRef.Type -eq 'Folder') {
            if ($currentView.Name -eq 'vm') {
                $reachedVmRoot = $true
            }
            elseif ($currentView.Name) {
                $segments += $currentView.Name
            }
        }

        if (-not $currentView.Parent) {
            break
        }

        if ($currentView.Parent.Type -eq 'Datacenter') {
            break
        }

        $currentRef = $currentView.Parent
    }

    if ($segments.Count -gt 0) {
        [array]::Reverse($segments)
        return ($segments -join '\')
    }

    if ($reachedVmRoot) {
        return 'Root VM Folder'
    }

    return ''
}

# -----------------------------
# Report arrays
# -----------------------------
$ContentLibraryReport = @()
$CustomSpecReport     = @()
$TemplateReport       = @()

# -----------------------------
# Collect data
# -----------------------------
foreach ($vCenter in $vCenters) {
    Write-Host "Connecting to $vCenter..." -ForegroundColor Yellow
    $viServer  = $null
    $cisServer = $null

    try {
        $viServer  = Connect-VIServer  -Server $vCenter -Credential $Credential -ErrorAction Stop
        $cisServer = Connect-CisServer -Server $vCenter -Credential $Credential -ErrorAction Stop

        # Customization Spec Manager view
        $customizationSpecManager = Get-View -Id $viServer.ExtensionData.Content.CustomizationSpecManager -Server $viServer -ErrorAction SilentlyContinue

        # Cache Distributed Portgroup names by Key so Network shows Portgroup instead of DVSwitch/UUID
        $dvPortgroupCache = @{}
        $dvPortgroups = Get-View -Server $viServer -ViewType DistributedVirtualPortgroup -Property Key,Name -ErrorAction SilentlyContinue
        foreach ($dvpg in $dvPortgroups) {
            if ($dvpg.Key -and -not $dvPortgroupCache.ContainsKey($dvpg.Key)) {
                $dvPortgroupCache[$dvpg.Key] = $dvpg.Name
            }
        }

        # -----------------------------
        # 1. Content Library inventory
        # -----------------------------
        $contentLibraryService     = Get-CisService -Name 'com.vmware.content.library'      -Server $cisServer
        $contentLibraryItemService = Get-CisService -Name 'com.vmware.content.library.item' -Server $cisServer

        $libraryIds = $contentLibraryService.list()

        foreach ($libraryIdRaw in $libraryIds) {
            $libraryId = Get-CisIdentifierValue -Identifier $libraryIdRaw
            if (-not $libraryId) {
                continue
            }

            $library = $contentLibraryService.get($libraryId)
            if (-not $library) {
                continue
            }

            $libraryName = Get-NestedPropertyValue -Object $library -PropertyPaths @('Name','name')
            $libraryType = Get-NestedPropertyValue -Object $library -PropertyPaths @('Type','type')

            $publishingEnabled = Get-NestedPropertyValue -Object $library -PropertyPaths @(
                'Publish_Info.Published',
                'publish_info.published'
            )

            $automaticSync = Get-NestedPropertyValue -Object $library -PropertyPaths @(
                'Subscription_Info.Automatic_Sync_Enabled',
                'subscription_info.automatic_sync_enabled'
            )

            $creationDate = Get-NestedPropertyValue -Object $library -PropertyPaths @(
                'Creation_Time',
                'creation_time'
            )

            $lastModifiedDate = Get-NestedPropertyValue -Object $library -PropertyPaths @(
                'Last_Modified_Time',
                'last_modified_time'
            )

            $itemIds = @()
            try {
                $itemIds = $contentLibraryItemService.list($libraryId)
            }
            catch {
                $itemIds = @()
            }

            if ($itemIds) {
                foreach ($itemIdRaw in $itemIds) {
                    $itemId = Get-CisIdentifierValue -Identifier $itemIdRaw
                    if (-not $itemId) {
                        continue
                    }

                    $item = $null
                    try {
                        $item = $contentLibraryItemService.get($itemId)
                    }
                    catch {
                        $item = $null
                    }

                    $itemName = ''
                    $itemType = ''
                    $itemCreationDate = ''
                    $itemLastModifiedDate = ''

                    if ($item) {
                        $itemName = Get-NestedPropertyValue -Object $item -PropertyPaths @('Name','name')
                        $itemType = Get-NestedPropertyValue -Object $item -PropertyPaths @('Type','type')

                        $itemCreationDate = Get-NestedPropertyValue -Object $item -PropertyPaths @(
                            'Creation_Time',
                            'creation_time'
                        )

                        $itemLastModifiedDate = Get-NestedPropertyValue -Object $item -PropertyPaths @(
                            'Last_Modified_Time',
                            'last_modified_time'
                        )
                    }

                    $ContentLibraryReport += [PSCustomObject]@{
                        vCenter                     = $vCenter
                        LibraryName                 = Convert-ToDisplayString $libraryName
                        ItemName                    = Convert-ToDisplayString $itemName
                        ItemType                    = Convert-ToDisplayString $itemType
                        Type                        = Convert-ToDisplayString $libraryType
                        'Publishing Enabled'        = Convert-ToDisplayString (Convert-BoolToYesNo $publishingEnabled)
                        'Automatic Synchronization' = Convert-ToDisplayString (Convert-BoolToYesNo $automaticSync)
                        'Creation Date'             = Convert-ToDisplayString ($(if ($itemCreationDate) { $itemCreationDate } else { $creationDate }))
                        'Last Modified Date'        = Convert-ToDisplayString ($(if ($itemLastModifiedDate) { $itemLastModifiedDate } else { $lastModifiedDate }))
                    }
                }
            }
            else {
                $ContentLibraryReport += [PSCustomObject]@{
                    vCenter                     = $vCenter
                    LibraryName                 = Convert-ToDisplayString $libraryName
                    ItemName                    = ''
                    ItemType                    = ''
                    Type                        = Convert-ToDisplayString $libraryType
                    'Publishing Enabled'        = Convert-ToDisplayString (Convert-BoolToYesNo $publishingEnabled)
                    'Automatic Synchronization' = Convert-ToDisplayString (Convert-BoolToYesNo $automaticSync)
                    'Creation Date'             = Convert-ToDisplayString $creationDate
                    'Last Modified Date'        = Convert-ToDisplayString $lastModifiedDate
                }
            }
        }

        # -----------------------------
        # 2. VM Customization Specifications
        # -----------------------------
        $specs = Get-OSCustomizationSpec -Server $viServer -ErrorAction SilentlyContinue

        foreach ($spec in $specs) {
            $guestOS                 = ''
            $lastModifiedDate        = ''
            $fullName                = ''
            $organizationName        = ''
            $namingScheme            = ''
            $namingPrefix            = ''
            $productKeyConfigured    = ''
            $timeZoneSet             = 'No'
            $adminPasswordConfigured = ''
            $autoLogonCount          = ''
            $guiRunOnce              = ''
            $domain                  = ''
            $workgroup               = ''
            $domainUsername          = ''
            $nicMappingSummary       = ''

            $specItem = $null
            $identity = $null

            if ($customizationSpecManager) {
                try {
                    $specItem = $customizationSpecManager.GetCustomizationSpec($spec.Name)
                }
                catch {
                    $specItem = $null
                }
            }

            if ($specItem -and $specItem.Info) {
                if ($specItem.Info.Type) {
                    $guestOS = $specItem.Info.Type
                }

                if ($specItem.Info.LastUpdateTime) {
                    $lastModifiedDate = $specItem.Info.LastUpdateTime
                }
            }

            if (-not $guestOS) {
                $guestOS = Get-NestedPropertyValue -Object $spec -PropertyPaths @(
                    'OSType',
                    'OsType',
                    'Type'
                )
            }

            if (-not $lastModifiedDate) {
                $lastModifiedDate = Get-NestedPropertyValue -Object $spec -PropertyPaths @(
                    'LastModifiedTime',
                    'LastUpdateTime',
                    'ModificationTime'
                )
            }

            if ($specItem -and $specItem.Spec -and $specItem.Spec.Identity) {
                $identity = $specItem.Spec.Identity
                $identityType = $identity.GetType().Name

                switch ($identityType) {
                    'CustomizationSysprep' {
                        if ($identity.UserData) {
                            if ($identity.UserData.FullName) {
                                $fullName = $identity.UserData.FullName
                            }

                            if ($identity.UserData.OrgName) {
                                $organizationName = $identity.UserData.OrgName
                            }

                            $namingInfo = Get-CustomizationNamingInfo -NamingObject $identity.UserData.ComputerName
                            if ($namingInfo) {
                                $namingScheme = $namingInfo.Scheme
                                $namingPrefix = $namingInfo.Prefix
                            }

                            if ($identity.UserData.ProductId) {
                                $productKeyConfigured = 'Yes'
                            }
                            else {
                                $productKeyConfigured = 'No'
                            }
                        }

                        if ($identity.GuiUnattended) {
                            if ($identity.GuiUnattended.PSObject.Properties['TimeZone'] -and $null -ne $identity.GuiUnattended.TimeZone -and "$($identity.GuiUnattended.TimeZone)" -ne '') {
                                $timeZoneSet = 'Yes'
                            }

                            if ($identity.GuiUnattended.PSObject.Properties['AutoLogonCount'] -and $null -ne $identity.GuiUnattended.AutoLogonCount) {
                                $autoLogonCount = $identity.GuiUnattended.AutoLogonCount
                            }

                            if ($identity.GuiUnattended.PSObject.Properties['Password'] -and $identity.GuiUnattended.Password) {
                                $adminPasswordConfigured = 'Yes'
                            }
                            else {
                                $adminPasswordConfigured = 'No'
                            }
                        }

                        if ($identity.GuiRunOnce -and $identity.GuiRunOnce.CommandList) {
                            $guiRunOnce = Convert-ToDisplayString $identity.GuiRunOnce.CommandList
                        }

                        if ($identity.Identification) {
                            if ($identity.Identification.JoinDomain) {
                                $domain = $identity.Identification.JoinDomain
                            }

                            if ($identity.Identification.JoinWorkgroup) {
                                $workgroup = $identity.Identification.JoinWorkgroup
                            }

                            if ($identity.Identification.DomainAdmin) {
                                $domainUsername = $identity.Identification.DomainAdmin
                            }
                        }
                    }

                    'CustomizationLinuxPrep' {
                        if ($identity.PSObject.Properties['Domain'] -and $identity.Domain) {
                            $domain = $identity.Domain
                        }

                        if ($identity.PSObject.Properties['TimeZone'] -and $null -ne $identity.TimeZone -and "$($identity.TimeZone)" -ne '') {
                            $timeZoneSet = 'Yes'
                        }

                        $namingInfo = Get-CustomizationNamingInfo -NamingObject $identity.HostName
                        if ($namingInfo) {
                            $namingScheme = $namingInfo.Scheme
                            $namingPrefix = $namingInfo.Prefix
                        }
                    }

                    'CustomizationSysprepText' {
                        # Unattend XML/text-based customization. Leave advanced fields blank.
                    }
                }
            }

            try {
                $nicMappings = Get-OSCustomizationNicMapping -OSCustomizationSpec $spec -Server $viServer -ErrorAction SilentlyContinue
                if ($nicMappings) {
                    $nicMappingSummary = Get-CustomizationNicSummary -NicMappings $nicMappings
                }
            }
            catch {
                $nicMappingSummary = ''
            }

            $CustomSpecReport += [PSCustomObject]@{
                vCenter                     = $vCenter
                SpecName                    = $spec.Name
                Type                        = $spec.Type
                Description                 = $spec.Description
                'Guest OS'                  = Convert-ToDisplayString $guestOS
                'Full Name'                 = Convert-ToDisplayString $fullName
                'Organization Name'         = Convert-ToDisplayString $organizationName
                'Naming Scheme'             = Convert-ToDisplayString $namingScheme
                'Naming Prefix'             = Convert-ToDisplayString $namingPrefix
                'Product Key Configured'    = Convert-ToDisplayString $productKeyConfigured
                'Admin Password Configured' = Convert-ToDisplayString $adminPasswordConfigured
                'Auto Logon Count'          = Convert-ToDisplayString $autoLogonCount
                'Time Zone Set'             = Convert-ToDisplayString $timeZoneSet
                'GuiRunOnce'                = Convert-ToDisplayString $guiRunOnce
                Domain                      = Convert-ToDisplayString $domain
                Workgroup                   = Convert-ToDisplayString $workgroup
                'Domain Username'           = Convert-ToDisplayString $domainUsername
                'NIC Mapping Summary'       = Convert-ToDisplayString $nicMappingSummary
                'Last Modified Date'        = Convert-ToDisplayString $lastModifiedDate
            }
        }

        # -----------------------------
        # 3. VM Templates
        # -----------------------------
        $hostCache       = @{}
        $clusterCache    = @{}
        $folderViewCache = @{}

        $templateViews = Get-View -Server $viServer -ViewType VirtualMachine -Property Name,Config,Runtime,Parent -ErrorAction SilentlyContinue |
            Where-Object { $_.Config -and $_.Config.Template -eq $true }

        foreach ($templateView in $templateViews) {
            $guestOS             = ''
            $version             = ''
            $hostName            = ''
            $clusterName         = ''
            $vSphereFolder       = ''
            $toolsVersion        = ''
            $toolsAutoUpgrade    = ''
            $cpuCount            = ''
            $ram                 = ''
            $storage             = ''
            $network             = ''
            $encryptionStatus    = 'Not Encrypted'
            $tags                = ''
            $notes               = ''

            if ($templateView.Config) {
                # Guest OS
                if ($templateView.Config.GuestFullName) {
                    $guestOS = $templateView.Config.GuestFullName
                }
                elseif ($templateView.Config.GuestId) {
                    $guestOS = $templateView.Config.GuestId
                }

                # VM hardware version
                $version = $templateView.Config.Version

                # VMware Tools version
                if ($templateView.Config.Tools -and $templateView.Config.Tools.ToolsVersion) {
                    $toolsVersion = $templateView.Config.Tools.ToolsVersion
                }

                # VMware Tools Auto Upgrade policy
                if ($templateView.Config.Tools -and $templateView.Config.Tools.ToolsUpgradePolicy) {
                    $toolsAutoUpgrade = $templateView.Config.Tools.ToolsUpgradePolicy
                }

                # CPU count
                if ($templateView.Config.Hardware -and $templateView.Config.Hardware.NumCPU -ne $null) {
                    $cpuCount = $templateView.Config.Hardware.NumCPU
                }

                # RAM in GB
                if ($templateView.Config.Hardware -and $templateView.Config.Hardware.MemoryMB -ne $null) {
                    $memoryGB = $templateView.Config.Hardware.MemoryMB / 1024
                    $ram = Format-DecimalString -Value $memoryGB -Suffix 'GB'
                }

                # Storage in GB (sum of all virtual disks)
                if ($templateView.Config.Hardware -and $templateView.Config.Hardware.Device) {
                    $virtualDisks = $templateView.Config.Hardware.Device | Where-Object { $_ -is [VMware.Vim.VirtualDisk] }

                    if ($virtualDisks) {
                        $totalDiskKB = ($virtualDisks | Measure-Object -Property CapacityInKB -Sum).Sum
                        if ($null -ne $totalDiskKB) {
                            $storageGB = $totalDiskKB / 1MB
                            $storage = Format-DecimalString -Value $storageGB -Suffix 'GB'
                        }
                    }

                    # Network names / assigned network group
                    $networkNames = foreach ($device in ($templateView.Config.Hardware.Device | Where-Object { $_ -is [VMware.Vim.VirtualEthernetCard] })) {

                        if ($device.Backing -is [VMware.Vim.VirtualEthernetCardNetworkBackingInfo]) {
                            if ($device.Backing.DeviceName) {
                                $device.Backing.DeviceName
                                continue
                            }
                        }

                        if ($device.Backing -is [VMware.Vim.VirtualEthernetCardDistributedVirtualPortBackingInfo]) {
                            $portgroupKey = $device.Backing.Port.PortgroupKey

                            if ($portgroupKey -and $dvPortgroupCache.ContainsKey($portgroupKey)) {
                                $dvPortgroupCache[$portgroupKey]
                                continue
                            }
                        }

                        if ($device.Backing -is [VMware.Vim.VirtualEthernetCardOpaqueNetworkBackingInfo]) {
                            if ($device.Backing.OpaqueNetworkName) {
                                $device.Backing.OpaqueNetworkName
                                continue
                            }
                        }

                        if ($device.DeviceInfo -and $device.DeviceInfo.Summary) {
                            $device.DeviceInfo.Summary
                        }
                    }

                    if ($networkNames) {
                        $network = Convert-ToDisplayString ($networkNames | Sort-Object -Unique)
                    }

                    # Encryption status - check VM home and virtual disks
                    $encryptedDisks = $templateView.Config.Hardware.Device | Where-Object {
                        $_ -is [VMware.Vim.VirtualDisk] -and
                        $_.Backing -and
                        $_.Backing.PSObject.Properties['KeyId'] -and
                        $_.Backing.KeyId
                    }

                    if (($templateView.Config.PSObject.Properties['KeyId'] -and $templateView.Config.KeyId) -or $encryptedDisks) {
                        $encryptionStatus = 'Encrypted'
                    }
                }

                # Notes / annotation
                if ($templateView.Config.Annotation) {
                    $notes = $templateView.Config.Annotation
                }
            }

            # vSphere Folder
            if ($templateView.Parent) {
                $vSphereFolder = Get-vSphereFolderPath -ParentMoRef $templateView.Parent -Server $viServer -ViewCache $folderViewCache
            }

            # Host / Cluster
            if ($templateView.Runtime -and $templateView.Runtime.Host) {
                $hostKey = $templateView.Runtime.Host.Value

                if (-not $hostCache.ContainsKey($hostKey)) {
                    $hostCache[$hostKey] = Get-View -Id $templateView.Runtime.Host -Property Name,Parent -Server $viServer -ErrorAction SilentlyContinue
                }

                $hostView = $hostCache[$hostKey]

                if ($hostView) {
                    $hostName = $hostView.Name

                    if ($hostView.Parent) {
                        $clusterKey = $hostView.Parent.Value

                        if (-not $clusterCache.ContainsKey($clusterKey)) {
                            $clusterCache[$clusterKey] = Get-View -Id $hostView.Parent -Property Name -Server $viServer -ErrorAction SilentlyContinue
                        }

                        $clusterView = $clusterCache[$clusterKey]

                        if ($clusterView) {
                            $clusterName = $clusterView.Name
                        }
                    }
                }
            }

            # Tags
            try {
                $templateObject = Get-VIObjectByVIView -VIObject $templateView -ErrorAction Stop
                $tagAssignments = Get-TagAssignment -Entity $templateObject -Server $viServer -ErrorAction SilentlyContinue

                if ($tagAssignments) {
                    $tags = Convert-ToDisplayString (($tagAssignments | Select-Object -ExpandProperty Tag | Select-Object -ExpandProperty Name) | Sort-Object -Unique)
                }
            }
            catch {
                # Leave blank if tag lookup fails
            }

            $TemplateReport += [PSCustomObject]@{
                vCenter                     = $vCenter
                TemplateName                = $templateView.Name
                'vSphere Folder'            = Convert-ToDisplayString $vSphereFolder
                GuestOS                     = $guestOS
                Version                     = $version
                Host                        = $hostName
                Cluster                     = $clusterName
                'VMwareTools Version'       = Convert-ToDisplayString $toolsVersion
                'VMware Tools AutoUpgradge' = Convert-ToDisplayString $toolsAutoUpgrade
                CPU                         = Convert-ToDisplayString $cpuCount
                RAM                         = $ram
                Storage                     = $storage
                Network                     = $network
                'Encryption Status'         = Convert-ToDisplayString $encryptionStatus
                Tags                        = Convert-ToDisplayString $tags
                Notes                       = Convert-ToDisplayString $notes
            }
        }

        Write-Host "Finished $vCenter" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed on $vCenter : $($_.Exception.Message)"
    }
    finally {
        if ($cisServer) {
            Disconnect-CisServer -Server $cisServer -Confirm:$false | Out-Null
        }

        if ($viServer) {
            Disconnect-VIServer -Server $viServer -Confirm:$false | Out-Null
        }
    }
}

# -----------------------------
# Prevent empty sheet issues
# -----------------------------
if (-not $ContentLibraryReport) {
    $ContentLibraryReport = @([PSCustomObject]@{ Message = 'No data found' })
}

if (-not $CustomSpecReport) {
    $CustomSpecReport = @([PSCustomObject]@{ Message = 'No data found' })
}

if (-not $TemplateReport) {
    $TemplateReport = @([PSCustomObject]@{ Message = 'No data found' })
}

# -----------------------------
# Export to Excel
# -----------------------------
Write-Host "Creating Excel report..." -ForegroundColor Cyan

$ContentLibraryReport | Export-Excel -Path $OutputFile -WorksheetName 'ContentLibrary' -AutoSize -AutoFilter -FreezeTopRow -ClearSheet
$CustomSpecReport     | Export-Excel -Path $OutputFile -WorksheetName 'CustomSpecs'   -AutoSize -AutoFilter -FreezeTopRow -ClearSheet
$TemplateReport       | Export-Excel -Path $OutputFile -WorksheetName 'Templates'     -AutoSize -AutoFilter -FreezeTopRow -ClearSheet

Write-Host "Report created: $OutputFile" -ForegroundColor Green
