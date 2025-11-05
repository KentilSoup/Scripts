# ------------------------------------------------------------
# Robocopy-DiskToDisk-Logging-v1.ps1
# Created By: Kent Fulton
# Last Edited: 11-05-2025
# ------------------------------------------------------------
# Clone C: to D: using Robocopy
# Make sure to adjust $Source and $Destination before running.
#   Robocopy parameters:
#     /MIR - Mirror source to destination (adds & deletes to match)
#     /COPYALL - Copy all attributes (data, ACLs, timestamps, owner, audit info)
#     /XJ - Exclude junction points (avoids infinite loops)
#     /R:3 /W:5 - Retry 3 times, wait 5 seconds between
#     /MT:32 - Multithreaded (adjust thread count to your CPU)
#     /FFT - Tolerant of FAT timestamp differences
#     /LOG+ - Append to log file
# ------------------------------------------------------------
# WARNING: USE THIS SCRIPT AT YOUR OWN RISK
# ------------------------------------------------------------
# This script performs a full mirror copy of the C: drive to D:
# using Robocopy with /MIR (Mirror) and /COPYALL options.
#
# IMPORTANT:
# - /MIR will DELETE files on the destination that do not exist
#   on the source. This can result in DATA LOSS if D: contains
#   important files.
# - Ensure $Source and $Destination are correct before running.
# - Do NOT run this on a live system drive unless you understand
#   the implications.
# - Always back up critical data before proceeding.
# - Run as Administrator for proper permissions.
# - Review the log file after completion for errors or skipped files.
#
# By using this script, you accept full responsibility for any
# data loss, corruption, or system issues that may occur.
# ------------------------------------------------------------
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
# ------------------------------------------------------------
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
# ------------------------------------------------------------

$Source = "C:\"
$Destination = "D:\"
$LogFile = "D:\CloneLog.txt"

Write-Host "Starting clone from $Source to $Destination..."
Write-Host "Logging to $LogFile"
Write-Host "This may take a while. Please wait..."

robocopy $Source $Destination /MIR /COPYALL /XJ /R:3 /W:5 /MT:32 /FFT /LOG+:"$LogFile"

Write-Host "Clone complete. Review the log file at $LogFile"
