# -----------------------------------------------
# Export-AD-Group-Members-Terminal-v1.ps1
# Created By: Kent Fulton
# Last Edited: 09-30-2025
# -----------------------------------------------
# This PowerShell script retrieves all members of a specified Active Directory group.
# It collects detailed information for user and computer objects:
# - For users: Display Name, Logon Name, Email, Job Title, City, State, Manager
# - For computers: Name, Operating System, Description
# Results are exported to a CSV file in the current user's profile directory.
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

param (
    [string]$GroupName = "ExampleADGroup"
)

Import-Module ActiveDirectory

$members = Get-ADGroupMember -Identity $GroupName -Recursive
$results = @()

foreach ($member in $members) {
    if ($member.objectClass -eq 'user') {
        $user = Get-ADUser -Identity $member.DistinguishedName -Properties DisplayName, SamAccountName, Mail, Title, City, State, Manager
        $managerName = if ($user.Manager) { (Get-ADUser -Identity $user.Manager -Properties DisplayName).DisplayName } else { "None" }

        $results += [PSCustomObject]@{
            Type        = "User"
            DisplayName = $user.DisplayName
            LogonName   = $user.SamAccountName
            Email       = $user.Mail
            JobTitle    = $user.Title
            City        = $user.City
