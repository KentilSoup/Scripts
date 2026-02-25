# -----------------------------------------------
# Add-BuiltinAdmins-ToShares-v1.ps1
# Created By: Kent Fulton
# Last Edited: 02-25-2026
# -----------------------------------------------
# PURPOSE:
#   Adds BUILTIN\Administrators with Full Control to the *SHARE* permissions
#   for the specific \\Server\Share entries listed below.
#   - Only SHARE ACLs are modified (SMB share permissions). NTFS ACLs are NOT touched.
#   - The script does NOT rename or otherwise modify the shares.
#   - Output is quiet by default; it prints:
#       * one header line the first time a change or failure occurs, and
#       * "Changed:" lines only when a change was actually made, or
#       * "FAILED:" lines if a share/server has an issue.
#   - The loop continues even if a share is missing or a server is unreachable.
#
# HOW IT WORKS:
#   1) Parse each UNC (\\Server\Share) into server and share name.
#   2) Connect to the server using a CIM session.
#   3) Read current SHARE ACL and check for BUILTIN\Administrators = Full.
#   4) If missing or lower rights, revoke the old ACE (if present) and grant Full.
#   5) Print a "Changed:" line only when an update occurs; otherwise be silent.
#   6) If anything fails (e.g., share not found), print a "FAILED:" line and continue.
#
# NOTES:
#   - Requires the SmbShare module (available on Windows 8/Server 2012+).
#   - You must have administrative rights on the target servers.
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

# Make everything quiet by default (we only emit our own result lines)
$ErrorActionPreference = 'Stop'              # Make errors throw so they hit our catch
$WarningPreference     = 'SilentlyContinue'  # Suppress warnings from cmdlets
$InformationPreference = 'SilentlyContinue'  # Suppress informational messages
$ProgressPreference    = 'SilentlyContinue'  # Suppress progress bars

# Exact list of target shares to process (each must be \\Server\Share)
# IMPORTANT: Keep the closing '@ at column 1 (no leading spaces) if editing in ISE.
$paths = @'
\\HOSTNAME\TestShare
\\HOSTNAME\TestShare2
'@ -split "`r?`n"

# Safety: ignore admin/special shares if they ever show up in the list by mistake
$skipShares = @('C$','ADMIN$','IPC$','PRINT$','FAX$')

# Header is printed only once—right before the first change or failure line
$printedHeader = $false
function Write-HeaderOnce {
    param([string]$title = "RESULTS")
    if (-not $script:printedHeader) {
        Write-Output ""  # blank line to visually separate any ISE echo from our output
        Write-Output "----- $title ($(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -----"
        $script:printedHeader = $true
    }
}

foreach ($p in $paths) {
    if ([string]::IsNullOrWhiteSpace($p)) { continue }   # skip blank lines

    # Parse \\Server\Share -> $server, $share
    $server, $share = $p.TrimStart('\').Split('\', 2)

    # Skip if an admin/special share sneaks into the list
    if ($skipShares -contains $share.ToUpperInvariant()) { continue }

    $s = $null
    try {
        # Open a CIM session to the target server (uses DCOM by default)
        $s = New-CimSession -ComputerName $server

        # Get existing SHARE ACEs for BUILTIN\Administrators (Allow)
        # Note: Get-SmbShareAccess reads *share* permissions only (not NTFS)
        $acl = Get-SmbShareAccess -CimSession $s -Name $share -ErrorAction Stop |
               Where-Object { $_.Name -ieq 'BUILTIN\Administrators' -and $_.AccessControlType -eq 'Allow' }

        # Determine if Full Control is already present
        $hasFull = $false
        if ($acl) {
            # AccessRight can be a scalar or array depending on version—coerce to array and check
            $rights = @($acl.AccessRight)
            if ($rights -contains 'Full' -or $rights -contains 'FullControl') { $hasFull = $true }
        }

        if (-not $hasFull) {
            # If an existing ACE exists with lesser rights, remove it to avoid duplicates
            if ($acl) {
                $null = Revoke-SmbShareAccess -CimSession $s -Name $share -AccountName 'BUILTIN\Administrators' -Force -Confirm:$false -ErrorAction Stop
            }

            # Grant Full Control (SHARE ACL only). Does not affect NTFS.
            $null = Grant-SmbShareAccess -CimSession $s -Name $share -AccountName 'BUILTIN\Administrators' -AccessRight Full -Force -Confirm:$false -ErrorAction Stop

            # Print header once, then the change line
            Write-HeaderOnce -title "SHARE PERMISSION CHANGES"
            Write-Output "Changed: \\$server\$share → BUILTIN\Administrators set to Full"
        }
        # If already has Full, remain silent (no output)

    } catch {
        # Any error (e.g., share not found, server unreachable, permission denied)
        # is reported and the loop continues to the next entry.
        Write-HeaderOnce -title "SHARE PERMISSION CHANGES"
        Write-Output "FAILED: \\$server\$share → $($_.Exception.Message)"
    } finally {
        # Always close the CIM session
        if ($s) { Remove-CimSession $s | Out-Null }
    }
}
