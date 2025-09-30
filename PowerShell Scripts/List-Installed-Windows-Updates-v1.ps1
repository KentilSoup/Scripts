# ================================================
# PowerShell Script: List-Installed-Windows-Updates-v1.ps1
# Author: Kent Fulton
# Last Edited: 09-30-2025
# Description:
#   - Retrieves a list of all installed Windows updates (hotfixes).
#   - Displays:
#       - Description: Type of update (e.g., Security Update)
#       - HotFixID: KB number of the update
#       - InstalledOn: Date the update was installed
#   - Sorts the updates by installation date in descending order
#     so the most recent updates appear first.
#   - Output is formatted as a clean, readable table.
#   - Useful for:
#       - Verifying patch compliance
#       - Troubleshooting recent system changes
#       - Auditing update history
# ================================================

# List all installed updates with their installation date and time
Get-HotFix |
Select-Object Description, HotFixID, InstalledOn |
Sort-Object InstalledOn -Descending |
