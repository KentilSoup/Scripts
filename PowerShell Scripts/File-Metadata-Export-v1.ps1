# -----------------------------------------------
# File-Metadata-Export-v1.ps1
# Created By: Kent Fulton
# Last Edited: 09-30-2025
# -----------------------------------------------
# This PowerShell script recursively scans a specified directory for files
# and exports their full paths and last modified timestamps to a CSV file.
# The output file is saved to the current logged-in user's profile directory
# as "output.csv" for easy access.
# -----------------------------------------------

Get-ChildItem "F:\FileDirectory" -Recurse -File |
    Select-Object FullName, LastWriteTime |
    Export-Csv -Path "$env:USERPROFILE\output.csv" -NoTypeInformation
