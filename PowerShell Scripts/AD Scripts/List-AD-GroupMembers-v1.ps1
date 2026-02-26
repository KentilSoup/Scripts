# -------------------------------------------------------------
# List-AD-GroupMembers-v1.ps1
# Created By: Kent Fulton
# Last Edited: 02-26-2026
# -------------------------------------------------------------
# PURPOSE:
#   Outputs all user members of the specified AD group
#   as a single semicolon-delimited string and copies it to the
#   clipboard for easy pasting into AD group membership dialogs.
#
# WHAT IT DOES:
#   - Reads all members of the specified AD group (recursive)
#   - Filters to user accounts only
#   - Removes any whitespace or line breaks from usernames
#   - Produces a string like: user1;user2;user3;
#   - Copies the string to your clipboard and displays it
#
# WHAT IT DOES NOT:
#   - List other AD groups of the specified AD group.
# -------------------------------------------------------------
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
# -------------------------------------------------------------
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
# -------------------------------------------------------------

# Outputs "User1;User2;User3;" with no spaces or hidden line breaks.
Import-Module ActiveDirectory

# Specify AD Group
$group = "AD Group Example"

$members = Get-ADGroupMember -Identity $group -Recursive |
           Where-Object { $_.objectClass -eq "user" } |
           Select-Object -ExpandProperty SamAccountName |
           ForEach-Object {
               # Remove ALL whitespace characters (spaces, tabs, CR, LF)
               ($_ -replace '\s','').Trim()
           } |
           Where-Object { $_ -ne "" }

$out = [string]::Join(';', $members) + ';'
$out

# Copy to clipboard for easy paste into AD dialog
$out | Set-Clipboard

# Friendly confirmation
Write-Host "✔ Output copied to clipboard. You can paste it directly when adding members to an AD group." -ForegroundColor Green
