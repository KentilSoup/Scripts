# -----------------------------------------------
# Gather-Server-Inventory-v1.ps1
# Created By: Kent Fulton
# Last Edited: 09-30-2025
# -----------------------------------------------
# This PowerShell script collects detailed inventory data from a list of remote Windows servers.
# It performs the following tasks for each server:
# - Tests WinRM connectivity
# - Retrieves OS, CPU, RAM, and disk usage information
# - Lists installed server features using DISM (for Server OS)
# - Enumerates SMB shares
# - Queries DNS records (A, AAAA, CNAME, MX, PTR, TXT)
# - Retrieves Netdom aliases (if available)
# - Collects network configuration details (IP, subnet, gateway, DNS)
# - Lists enabled local user accounts
# The results are exported to a CSV file at C:\ServerInventory.csv.
# Any failures (e.g., unreachable servers or errors during data collection) are logged to C:\ServerInventoryFailures.csv.
# -----------------------------------------------
 
 # List your servers here
$servers = @("Server1", "Server2")  # Replace with your actual server names

$results = @()
$failures = @()

foreach ($server in $servers) {
    try {
        # Test remote connection
        if (-not (Test-WSMan -ComputerName $server -ErrorAction SilentlyContinue)) {
            Write-Warning "Cannot reach $server via WinRM."
            $failures += [PSCustomObject]@{
                ServerName = $server
                Error = "WinRM not available"
            }
            continue
        }

        $data = Invoke-Command -ComputerName $server -ScriptBlock {
            $computer = $env:COMPUTERNAME
            $osInfo = Get-CimInstance Win32_OperatingSystem
            $os = $osInfo.Caption + " " + $osInfo.Version

            $cpuName = (Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)
            $vcpuCount = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
            $cpu = "$cpuName ($vcpuCount vCPU)"

            $ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)

            $drives = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
                "$($_.Name): $([math]::Round($_.Used/1GB,2)) GB used / $([math]::Round(($_.Free + $_.Used)/1GB,2)) GB total"
            } | Sort-Object | Out-String
            $drives = $drives.Trim()

            # Get Domain Name
            $domain = (Get-CimInstance Win32_ComputerSystem).Domain

            # Installed Server Features fallback using DISM (works on all Server editions incl Core)
            $installedFeatures = ""
            if ($os -like "*Server*") {
                try {
                    $dismOutput = dism /online /get-features /format:table
                    $installed = ($dismOutput | Select-String "Enabled" | ForEach-Object {
                        ($_ -split '\s+')[0]
                    }) -join ", "
                    if ($installed) {
                        $installedFeatures = $installed
                    } else {
                        $installedFeatures = "No features enabled"
                    }
                }
                catch {
                    $installedFeatures = "Error retrieving features via DISM"
                }
            } else {
                $installedFeatures = "Not a Server OS"
            }

            # Get all SMB shares (including default admin shares)
            try {
                $shares = Get-SmbShare | Select-Object -ExpandProperty Name
                if ($shares.Count -gt 0) {
                    $sharesStr = $shares -join ", "
                }
                else {
                    $sharesStr = "No shares found"
                }
            } catch {
                $sharesStr = "Error retrieving shares"
            }

            # Query multiple DNS record types for hostname
            $dnsRecords = @()
            $recordTypes = @("A", "AAAA", "CNAME", "MX", "PTR", "TXT")
            foreach ($type in $recordTypes) {
                try {
                    $records = Resolve-DnsName -Name $computer -Type $type -ErrorAction SilentlyContinue
                    if ($records) {
                        foreach ($rec in $records) {
                            switch ($type) {
                                "A"     { $dnsRecords += "A: " + $rec.IPAddress }
                                "AAAA"  { $dnsRecords += "AAAA: " + $rec.IPAddress }
                                "CNAME" { $dnsRecords += "CNAME: " + $rec.NameHost }
                                "MX"    { $dnsRecords += "MX: " + $rec.NameExchange }
                                "PTR"   { $dnsRecords += "PTR: " + $rec.PTRDomainName }
                                "TXT"   { $dnsRecords += "TXT: " + ($rec.Strings -join " ") }
                            }
                        }
                    }
                } catch {
                    # Ignore errors for specific record types
                }
            }
            $dnsRecordsStr = if ($dnsRecords.Count -gt 0) { $dnsRecords -join "; " } else { "No DNS records found" }

            # Get Netdom aliases
            $netdomAliases = ""
            if (Get-Command netdom.exe -ErrorAction SilentlyContinue) {
                try {
                    $aliasesRaw = netdom computername $computer 2>&1
                    if ($aliasesRaw -is [System.Array]) {
                        $aliasesList = $aliasesRaw | Where-Object {$_ -match "Name:"} | ForEach-Object {
                            ($_ -split ":")[1].Trim()
                        }
                        $netdomAliases = if ($aliasesList.Count -gt 0) { $aliasesList -join ", " } else { "No netdom aliases" }
                    } else {
                        $netdomAliases = $aliasesRaw
                    }
                } catch {
                    $netdomAliases = "Error retrieving netdom aliases"
                }
            } else {
                $netdomAliases = "Netdom not available"
            }

            # Network info: IP, Subnet, Gateway, DNS servers
            $netConfigs = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
            $networkInfoList = foreach ($net in $netConfigs) {
                $ip = if ($net.IPAddress) { $net.IPAddress -join ", " } else { "N/A" }
                $subnet = if ($net.IPSubnet) { $net.IPSubnet -join ", " } else { "N/A" }
                $gateway = if ($net.DefaultIPGateway) { $net.DefaultIPGateway -join ", " } else { "N/A" }
                $dnsServers = if ($net.DNSServerSearchOrder) { $net.DNSServerSearchOrder -join ", " } else { "N/A" }

                "Desc: $($net.Description); IP: $ip; Subnet: $subnet; Gateway: $gateway; DNS Servers: $dnsServers"
            }
            $networkInfoStr = $networkInfoList -join " | "

            # Get all local users
            try {
                $localUsers = Get-CimInstance Win32_UserAccount -Filter "LocalAccount=True AND Disabled=False" | 
                              Select-Object -ExpandProperty Name
                $localUsersStr = if ($localUsers.Count -gt 0) { $localUsers -join ", " } else { "No local users found" }
            } catch {
                $localUsersStr = "Error retrieving local users"
            }

            [PSCustomObject]@{
                ServerName             = $computer
                OS                     = $os
                Domain                 = $domain
                CPU                    = $cpu
                RAM_GB                 = $ram
                Drives                 = $drives
                InstalledServerFeatures = $installedFeatures
                Shares                 = $sharesStr
                DNSRecords             = $dnsRecordsStr
                NetdomAliases          = $netdomAliases
                NetworkInfo            = $networkInfoStr
                LocalUsers             = $localUsersStr
            }
        } -ErrorAction Stop

        $results += $data
        Write-Host "Collected data from $server"
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Warning ("Failed to collect from " + $server + ": " + $errorMsg)
        $failures += [PSCustomObject]@{
            ServerName = $server
            Error = $errorMsg
        }
    }
}

# Export to CSV in C:\ selecting only your desired columns
$csvPath = "C:\ServerInventory.csv"
$results | Select-Object ServerName, Domain, OS, CPU, RAM_GB, Drives, InstalledServerFeatures, Shares, DNSRecords, NetdomAliases, NetworkInfo, LocalUsers | 
    Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Exported results to $csvPath"

if ($failures.Count -gt 0) {
    $failPath = "C:\ServerInventoryFailures.csv"
    $failures | Export-Csv -Path $failPath -NoTypeInformation -Encoding UTF8
    Write-Warning "Some servers failed to collect. See $failPath"
}
