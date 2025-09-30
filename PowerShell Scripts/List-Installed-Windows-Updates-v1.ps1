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
# DISCLAIMER
# ================================================
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
# ================================================

# List all installed updates with their installation date and time
Get-HotFix |
Select-Object Description, HotFixID, InstalledOn |
Sort-Object InstalledOn -Descending |
