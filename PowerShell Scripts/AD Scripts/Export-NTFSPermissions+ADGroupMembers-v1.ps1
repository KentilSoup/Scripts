# -----------------------------------------------
# Export-NTFSPermissions+ADGroupMembers-v1.ps1
# Created By: Kent Fulton
# Last Edited: 01-29-2026
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
# Description:
# This script retrieves NTFS permissions (ACLs) for a specified
# file or folder path and generates a report of all access entries.
#
# For each ACE (Access Control Entry), the script:
#   - Captures the full security identity (DOMAIN\User or DOMAIN\Group)
#   - Attempts to determine if the identity is an Active Directory group
#   - If the identity is a group, recursively enumerates all user members
#   - Records the NTFS permissions and access type (Allow/Deny)
#
# The results are exported to a CSV file for easy review and auditing.
#
# Requirements:
#   - Must be run by an account with:
#       • Read access to the target path
#       • Permission to query Active Directory
#   - ActiveDirectory PowerShell module must be available
#
# Output:
#   - CSV file containing:
#       Path, Identity, Members (if AD group), Permissions, AccessType
#
# Notes:
#   - If an identity is not an AD group, the Members field is left blank
#   - Useful for auditing DFS targets, file servers, and shared resources
# -----------------------------------------------

# ===== CONFIG =====
$Path = "\\Server\Path\File.txt"
$OutputFile = "$env:USERPROFILE\Desktop\NTFS_Permissions_Report.csv"

$Acl = Get-Acl $Path

$Results = foreach ($Ace in $Acl.Access) {

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
        # Identity is not an Active Directory group — skip member enumeration
    }

    [PSCustomObject]@{
        Path        = $Path
        Identity    = $RawIdentity
        Members     = $MembersList
        Permissions = $Ace.FileSystemRights
        AccessType  = $Ace.AccessControlType
    }
}

$Results | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8
Write-Host "Report exported to $OutputFile"
