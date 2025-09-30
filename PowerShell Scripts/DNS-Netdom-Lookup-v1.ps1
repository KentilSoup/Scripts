# -----------------------------------------------
# DNS-Netdom-Lookup-v1.ps1
# Created By: Kent Fulton
# Last Edited: 09-30-2025
# -----------------------------------------------
# This PowerShell script queries a specified server for DNS records and Netdom aliases.
# It performs the following tasks:
# - Iterates through common DNS record types (A, AAAA, CNAME, MX, NS, PTR, SOA, SRV, TXT)
# - Uses Resolve-DnsName to retrieve and display DNS record details
# - Executes the Netdom command to list alternate computer names (aliases)
# Output is displayed in the console for quick inspection.
# -----------------------------------------------
# DISCLAIMER
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

$server = "Server1"  # Replace with actual server name

Write-Host "`n--- DNS Records for $server ---`n"

# List of common DNS record types to query
$recordTypes = @("A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SRV", "TXT")

foreach ($type in $recordTypes) {
    Write-Host "`n[$type Records]"
    try {
        $records = Resolve-DnsName -Name $server -Type $type -ErrorAction SilentlyContinue
        if ($records) {
            $records | Format-Table Name, Type, TTL, IPAddress, NameHost, MailExchange, Text, -AutoSize
        } else {
            Write-Host "No $type records found."
        }
    } catch {
        Write-Host "Error retrieving $type records: $_"
    }
}

Write-Host "`n--- Netdom Aliases ---`n"

try {
    $netdomOutput = netdom computername $server 2>&1
    if ($netdomOutput -match "Alternate computer names") {
        $netdomOutput | ForEach-Object {
            if ($_ -match "^\s+(.+)$") {
                Write-Host "Alias: $($matches[1].Trim())"
            }
        }
    } else {
        Write-Host "No Netdom aliases found."
    }
} catch {
    Write-Host "Netdom command failed: $_"
}
