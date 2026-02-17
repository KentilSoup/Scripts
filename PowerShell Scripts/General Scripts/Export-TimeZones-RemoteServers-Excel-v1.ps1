# ----------------------------------------------------------
# Export-TimeZones-RemoteServers-Excel-v1.ps1
# Created By: Kent Fulton
# Creation Date: 02-17-2026
# Description:
#   - Reads a list of server names from servers.txt
#   - Runs Get-TimeZone remotely using Invoke-Command
#   - Exports results to a CSV file that opens in Excel
# ----------------------------------------------------------
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
# ----------------------------------------------------------
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
# ----------------------------------------------------------

# Read server names from text file
$servers = Get-Content "C:\Users\_____\Downloads\servers.txt"

# Query each server for its timezone
$out = foreach ($s in $servers) {
    Invoke-Command -ComputerName $s -ScriptBlock { Get-TimeZone } |
    Select-Object @{n="Server";e={$s}}, Id, DisplayName
}

# Export as real CSV (Excel-readable)
$out | Export-Csv "C:\Users\_____\Downloads\TimeZones_Output.csv" -NoTypeInformation
