# -----------------------------------------------
# Export-NTFSPermissions+ADGroupMembers-Excel-v1.ps1
# Created By: Kent Fulton
# Last Edited: 02-02-2026
# -----------------------------------------------
# Description:
# This script retrieves NTFS permissions (ACLs) for
# multiple files or folders specified via a text file
# containing UNC paths (one per line).
#
# For each path and each ACE (Access Control Entry),
# the script:
#   - Captures the full security identity (DOMAIN\User or DOMAIN\Group)
#   - Attempts to determine if the identity is an Active Directory group
#   - If the identity is a group, recursively enumerates all user members
#   - Records the NTFS permissions and access type (Allow/Deny)
#
# The results are exported to a single CSV file for
# easy review and auditing.
#
# Requirements:
#   - Must be run by an account with:
#       • Read access to all target paths
#       • Permission to query Active Directory
#   - ActiveDirectory PowerShell module must be available
#
# Input:
#   - Text file containing UNC paths (one per line)
#
# Output:
#   - CSV file containing:
#       Path, Identity, Members (if AD group),
#       Permissions, AccessType
#
# Notes:
#   - If a path does not exist, it is skipped and a warning is displayed
#   - If an identity is not an AD group, the Members field is left blank
#   - Useful for auditing DFS targets, file servers, and shared resources
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

$PathsFile = "$env:USERPROFILE\Desktop\paths.txt"
$OutputFile = "$env:USERPROFILE\Desktop\NTFS_Permissions_Report.csv"

$Paths = Get-Content $PathsFile | Where-Object { $_ -and $_.Trim() -ne "" }

$Results = foreach ($Path in $Paths) {

    if (-not (Test-Path $Path)) {
        Write-Warning "Path not found: $Path"
        continue
    }

    $Acl = Get-Acl $Path

    foreach ($Ace in $Acl.Access) {

        $RawIdentity = $Ace.IdentityReference.Value
        $SamName = $RawIdentity.Split('\')[-1]
        $MembersList = ""

        try {
            $Group = Get-ADGroup -Identity $SamName -ErrorAction Stop
            $Members = Get-ADGroupMember $Group -Recursive |
                       Where-Object { $_.objectClass -eq "user" } |
                       Select-Object -ExpandProperty SamAccountName

            if ($Members) {
                $MembersList = $Members -join ", "
            }
        }
        catch {
            # Not an AD group
        }

        [PSCustomObject]@{
            Path        = $Path
            Identity    = $RawIdentity
            Members     = $MembersList
            Permissions = $Ace.FileSystemRights
            AccessType  = $Ace.AccessControlType
        }
    }
}

$Results | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "Report exported to $OutputFile"
