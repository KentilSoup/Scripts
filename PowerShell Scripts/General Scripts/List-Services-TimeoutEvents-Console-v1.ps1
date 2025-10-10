# ================================================
# PowerShell Script: List-Services-TimeoutEvents-Console-v1.ps1
# Author: Kent Fulton
# Last Edited: 10-10-2025
# Description:
#   - Queries the Windows System event log for Event ID 7011
#     from the past 7 days.
#   - Event ID 7011 indicates a service timeout, meaning a
#     service did not respond within the expected time frame.
#   - This can help identify performance issues, stalled services,
#     or potential root causes of system instability.
#   - Outputs the results in a readable list format showing:
#       - TimeCreated: When the event occurred
#       - Id: The event ID (7011)
#       - Message: Details about the service that timed out
# ================================================
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
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

Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Id = 7011
    StartTime = (Get-Date).AddDays(-7)
    EndTime = Get-Date
} | Format-List TimeCreated, Id, Message
