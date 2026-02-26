# -------------------------------------------------------------
# Scan-ServersLocalAdmin-v1.ps1
# Created By: Kent Fulton
# Last Edited: 02-26-2026
# -------------------------------------------------------------
# This script audits whether a specified domain account is a
# member of the local Administrators group on a list of servers.
#
# WHAT THIS SCRIPT DOES:
#   - Checks for direct membership in the local Administrators group.
#   - Checks for indirect membership through any group inside
#     Administrators (one level deep).
#   - Translates each member to a security identifier (SID) when
#     possible to confirm identity.
#   - Shows a progress bar while processing each server.
#   - Reports direct, via-group, or no local admin rights per server.
#
# WHAT THIS SCRIPT DOES NOT DO:
#   - Does NOT resolve deeply nested AD group membership beyond
#     the first group inside Administrators.
#   - Does NOT resolve nested LOCAL groups beyond one level.
#
# This script should be used as an assistance tool and not as a
# definitive authorization audit without additional validation.
# -------------------------------------------------------------
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
# -------------------------------------------------------------
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
# -------------------------------------------------------------

# >>> Hard-code server names here <<<
$Servers = @(
"Server1",
"Server2",
"Server3"
)

# Account to audit
$Account = "domain\AD-Account-Example"

# Resolve target SID
try {
    $AccountSid = ([System.Security.Principal.NTAccount]$Account).
                  Translate([System.Security.Principal.SecurityIdentifier]).Value
} catch {
    Write-Error "Unable to resolve SID for $Account"
    exit
}

Write-Host "`nChecking membership for $Account ($AccountSid)`n"

# Progress bar setup
$total = $Servers.Count
$idx = 0

$results = foreach ($srv in $Servers) {
    $idx++
    $pct = [int](($0))
    Write-Progress -Id 1 -Activity "Auditing local admin membership" -Status "Starting $srv ($idx of $total)" -PercentComplete $pct

    $direct   = $false
    $viaGroup = $false
    $ErrMsg   = $null

    try {
        $adminGroup = [ADSI]"WinNT://$srv/Administrators,group"
        $members    = $adminGroup.psbase.Invoke("Members")

        $memberCount = 0
        foreach ($m in $members) {
            $memberCount++
            # Lightweight per-server progress (does not change overall percent)
            Write-Progress -Id 2 -ParentId 1 -Activity "Enumerating $srv" -Status "Member $memberCount..." -PercentComplete (($memberCount % 100))

            # Bind to each member
            $mo = $null
            try {
                $adspath = $m.GetType().InvokeMember('ADsPath','GetProperty',$null,$m,$null)
                $mo = [ADSI]$adspath
            } catch { continue }

            # Translate member to SID if possible
            $sid = $null
            try {
                $ntname = $mo.Path.Replace("WinNT://","").Replace("/","\")
                $sid = ([System.Security.Principal.NTAccount]$ntname).
                       Translate([System.Security.Principal.SecurityIdentifier]).Value
            } catch { }

            if ($sid -and $sid -eq $AccountSid) { $direct = $true }

            # If the member is a group, check one level deeper
            if (-not $direct -and $mo.SchemaClassName -eq "Group") {
                try {
                    $members2 = $mo.psbase.Invoke("Members")
                    foreach ($g in $members2) {
                        try {
                            $gpath = $g.GetType().InvokeMember('ADsPath','GetProperty',$null,$g,$null)
                            $gobj  = [ADSI]$gpath
                            $gname = $gobj.Path.Replace("WinNT://","").Replace("/","\")
                            $gsid  = ([System.Security.Principal.NTAccount]$gname).
                                     Translate([System.Security.Principal.SecurityIdentifier]).Value
                            if ($gsid -eq $AccountSid) { $viaGroup = $true }
                        } catch { continue }
                    }
                } catch { }
            }
        }
    } catch {
        $ErrMsg = $_.Exception.Message
    }

    # Clear per-server inner progress bar
    Write-Progress -Id 2 -ParentId 1 -Activity "Enumerating $srv" -Completed

    [pscustomobject]@{
        Server       = $srv
        Direct       = $direct
        ViaGroup     = $viaGroup
        IsLocalAdmin = ($direct -or $viaGroup)
        Error        = $ErrMsg
    }
}

# Complete the main progress bar
Write-Progress -Id 1 -Activity "Auditing local admin membership" -Completed

$results | Format-Table -AutoSize
