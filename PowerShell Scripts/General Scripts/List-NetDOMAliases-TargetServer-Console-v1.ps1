# -----------------------------------------------
# List-NetDOMAliases-TargetServer-Console-v1.ps1
# Created By: Kent Fulton
# Last Edited: 11-19-2025
# -----------------------------------------------
# Description:
# This script retrieves the primary computer name and any alternate
# names (aliases) for a specified server using the Netdom utility.
# It uses the '/enum' switch for clean output and formats the results
# to clearly identify the primary name and alternate names.
# -----------------------------------------------

$server = "SERVERNAME"  # Replace with your server name

Write-Host "`n--- Netdom Computer Names ---`n"

try {
    if (Get-Command netdom -ErrorAction SilentlyContinue) {
        $netdomOutput = netdom computername $server /enum 2>&1

        # Filter out empty lines, success message, and header
        $names = $netdomOutput | Where-Object {
            $_ -and ($_ -notmatch "The command completed successfully") -and ($_ -notmatch "All of the names")
        }

        if ($names.Count -gt 0) {
            # First name is Primary
            Write-Host "Primary Name: $($names[0])"
            # Remaining names are Aliases
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
