# -----------------------------------------------
# List-SharePermissions-Report-v1.ps1
# Created By: Kent Fulton
# Last Edited: 02-25-2026
# -----------------------------------------------
# PURPOSE:
#   Read-only report of current SMB *share* permissions (NOT NTFS) for the
#   \\Server\Share paths listed below. Prints each ACE as one line:
#     \\Server\Share | Scope=* | Account=Everyone | Type=Allow | Rights=Read
#
# NOTES:
#   - Uses Get-SmbShareAccess (reads *share ACLs only*).
#   - Requires SmbShare module (Windows 8/Server 2012+).
#   - Admin rights on target servers.
#   - In ISE, run with F5 (Run Script) to avoid paste-echo of code.
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

# Keep output clean; only show our own lines
$ErrorActionPreference = 'Stop'
$WarningPreference     = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'

# Exact list of target shares to report (each must be \\Server\Share)
# IMPORTANT (ISE): the closing '@ must be at column 1 (no leading spaces).
$paths = @'
\\HOSTNAME\TestShare
\\HOSTNAME\TestShare2
'@ -split "`r?`n"

# Safety: ignore admin/special shares if they appear by mistake
$skipShares = @('C$','ADMIN$','IPC$','PRINT$','FAX$')

# Print header once to separate any ISE echo from the report lines
$printedHeader = $false
function Write-HeaderOnce {
    if (-not $script:printedHeader) {
        Write-Output ""
        Write-Output "----- SHARE PERMISSIONS REPORT ($(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -----"
        $script:printedHeader = $true
    }
}

foreach ($p in $paths) {
    if ([string]::IsNullOrWhiteSpace($p)) { continue }

    # Parse \\Server\Share
    $server, $share = $p.TrimStart('\').Split('\', 2)

    # Skip admin/special shares if present
    if ($skipShares -contains $share.ToUpperInvariant()) { continue }

    $s = $null
    try {
        # Open CIM session (DCOM by default)
        $s = New-CimSession -ComputerName $server

        # Read share ACL (read-only)
        $acls = Get-SmbShareAccess -CimSession $s -Name $share -ErrorAction Stop

        # Emit header first time we output results
        Write-HeaderOnce

        if (-not $acls) {
            Write-Output "EMPTY:  \\$server\$share has no share ACEs"
            continue
        }

        # Print each ACE in a compact, readable line (no tables)
        foreach ($ace in $acls) {
            # IMPORTANT: AccountName is the user/group; Name is the ShareName.
            $account = $ace.AccountName
            $type    = $ace.AccessControlType  # Allow / Deny
            $scope   = $ace.ScopeName          # usually '*'
            # Rights can be scalar or array; join cleanly
            $rights  = ($ace.AccessRight -join ', ')
            Write-Output "\\$server\$share | Scope=$scope | Account=$account | Type=$type | Rights=$rights"
        }

    } catch {
        Write-HeaderOnce
        Write-Output "FAILED: \\$server\$share → $($_.Exception.Message)"
    } finally {
        if ($s) { Remove-CimSession $s | Out-Null }
    }
}
