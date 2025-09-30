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
