#---------------------------------------------------------------
# Name: Set-PowerCLI-VMToolsAutoUpgrade-v1.ps1
# Created By: Kent Fulton
# Last Updated: 05-05-2026
#---------------------------------------------------------------
# Updates VMware Tools upgrade policy for a list of VMs
# Reads VM names from a text file and sets policy to:
# - UpgradeAtPowerCycle (default)
# - Manual (optional section below)
# Requires VMware PowerCLI and vCenter connection
#---------------------------------------------------------------
# CAUTION:
# Setting VMware Tools to "UpgradeAtPowerCycle" enables automatic
# upgrades during VM reboot. This may:
# - Trigger unexpected reboots if combined with patching/automation
# - Cause brief service interruptions during upgrade
# - Introduce version changes without manual validation/testing
#
# Ensure compatibility with your environment and maintenance
# windows before enabling in production.
#---------------------------------------------------------------
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
#
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
#---------------------------------------------------------------


#---------------------------------------------------------------
# SET TOOLS UPGRADE POLICY TO UPGRADE AT POWER CYCLE
#---------------------------------------------------------------
$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
$vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
$vmConfigSpec.Tools.ToolsUpgradePolicy = "UpgradeAtPowerCycle"
$vms = Get-Content "C:\TargetVMs.txt"
Foreach ($vm in $vms)
{get-vm $vm | %{$_.Extensiondata.ReconfigVM($vmConfigSpec)}}


#---------------------------------------------------------------
# SET TOOLS UPGRADE POLICY TO MANUAL
#---------------------------------------------------------------
# $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
# $vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
# $vmConfigSpec.Tools.ToolsUpgradePolicy = "manual"
# $vms = Get-Content "C:\TargetVMs.txt"
# Foreach ($vm in $vms)
# {get-vm $vm | %{$_.Extensiondata.ReconfigVM($vmConfigSpec)}}
