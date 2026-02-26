# -----------------------------------------------
# Ping-Servers-v1.ps1
# Created By: Kent Fulton
# Last Edited: 02-26-2026
# -----------------------------------------------
# Simple Ping Script (With IP, DNS, Uptime + Table)
#
# WHAT THIS SCRIPT DOES:
# • Pings each server in the list to check if it is online or offline.
# • For online servers:
#     - Retrieves the server's IP address (DNS A record lookup).
#     - Retrieves the server's DNS name.
#     - Calculates uptime using the LastBootUpTime value.
# • Builds a clean, aligned results table.
# • Outputs the final table sorted by server name.
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

# Add your servers here
$servers = @(
"Server1"
"Server2"
"Server3"
)

# Collect results for nice, aligned table output
$results = @()

foreach ($server in $servers) {
    $online = Test-Connection -ComputerName $server -Count 1 -Quiet

    if ($online) {
        # Forward DNS (A record) lookup for IP + DNS
        try {
            $r = Resolve-DnsName -Name $server -Type A -ErrorAction Stop
            $ip  = ($r | Where-Object { $_.Type -eq "A" }).IPAddress
            $dns = ($r | Select-Object -First 1).Name
        } catch {
            $ip  = "N/A"
            $dns = "N/A"
        }

        # Uptime from LastBootUpTime
        try {
            $os = Get-CimInstance Win32_OperatingSystem -ComputerName $server -ErrorAction Stop
            $boot = $os.LastBootUpTime
            $ts   = New-TimeSpan -Start $boot -End (Get-Date)
            $uptime = "{0}d {1}h {2}m" -f $ts.Days, $ts.Hours, $ts.Minutes
        } catch {
            $uptime = "N/A"
        }

        $results += [pscustomobject]@{
            Server = $server
            Status = "ONLINE"
            IP     = $ip
            DNS    = $dns
            Uptime = $uptime
        }
    }
    else {
        $results += [pscustomobject]@{
            Server = $server
            Status = "OFFLINE"
            IP     = ""
            DNS    = ""
            Uptime = ""
        }
    }
}

# Show as a clean, auto-sized table (Excel-like grid in terminal)
$results | Sort-Object Server | Format-Table Server, Status, IP, DNS, Uptime -AutoSize
