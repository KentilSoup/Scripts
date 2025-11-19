# -----------------------------------------------
# List-DNS-NetDOMAliases-TargetServer-Console-v2.ps1
# Created By: Kent Fulton
# Last Edited: 11-19-2025
# -----------------------------------------------
# This script queries a specified server for common DNS record types:
# A, AAAA, CNAME, MX, NS, PTR, SOA, SRV, and TXT.
# It uses `Resolve-DnsName` to retrieve and display each record type.
# Additionally, it runs `netdom computername /enum` to list the primary
# computer name and any alternate names (aliases) associated with the server.
# Useful for verifying DNS configurations and aliasing in AD environments.
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

$server = "SERVERNAME"  # Replace with actual server name

Write-Host "`n--- DNS Records for $server ---`n"

# List of common DNS record types to query
$recordTypes = @("A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SRV", "TXT")

foreach ($type in $recordTypes) {
    Write-Host "`n[$type Records]"
    try {
        $records = Resolve-DnsName -Name $server -Type $type -ErrorAction SilentlyContinue
        if ($records) {
            $records | Format-Table Name, Type, TTL, IPAddress, NameHost, MailExchange, Text -AutoSize
        } else {
            Write-Host "No $type records found."
        }
    } catch {
        Write-Host "Error retrieving $type records: $_"
    }
}

Write-Host "`n--- Netdom Computer Names ---`n"

try {
    if (Get-Command netdom -ErrorAction SilentlyContinue) {
        $netdomOutput = netdom computername $server /enum 2>&1

        # Filter out empty lines, success message, and header
        $names = $netdomOutput | Where-Object {
            $_ -and ($_ -notmatch "The command completed successfully") -and ($_ -notmatch "All of the names")
        }

        if ($names.Count -gt 0) {
            Write-Host "Primary Name: $($names[0])"
            if ($names.Count -gt 1) {
                Write-Host "`nAlternate Names:"
                foreach ($alias in $names[1..($names.Count - 1)]) {
                    Write-Host " - $alias"
                }
            } else {
                Write-Host "`nNo alternate names found."
            }
        } else {
            Write-Host "No names found for $server."
        }
    } else {
        Write-Host "Netdom is not installed or not in PATH."
    }
} catch {
    Write-Host "Netdom command failed: $_"
}
