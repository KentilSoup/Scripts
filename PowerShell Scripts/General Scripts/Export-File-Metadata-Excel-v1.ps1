# -----------------------------------------------
# Export-File-Metadata-Excel-v1.ps1
# Created By: Kent Fulton
# Last Edited: 10-10-2025
# -----------------------------------------------
# This PowerShell script recursively scans a specified directory for files
# and exports their full paths and last modified timestamps to a CSV file.
# The output file is saved to the current logged-in user's profile directory
# as "output.csv" for easy access.
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

Get-ChildItem "F:\FileDirectory" -Recurse -File |
    Select-Object FullName, LastWriteTime |
    Export-Csv -Path "$env:USERPROFILE\output.csv" -NoTypeInformation
