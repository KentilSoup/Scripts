# ================================================
# PowerShell Script: List-Service-Timeout-Events-v1.ps1
# Author: Kent Fulton
# Last Edited: 09-30-2025
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

Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Id = 7011
    StartTime = (Get-Date).AddDays(-7)
    EndTime = Get-Date
} | Format-List TimeCreated, Id, Message
