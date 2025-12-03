# ============================================================
# Export-AvailablePerformanceCounters-Excel-v1.ps1
# Created By: Kent Fulton
# Last Edited: 12-03-2025
#
# Description: This command lists all available performance
# counters on the local system and saves them to a text file.
# ============================================================
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
# ============================================================
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
# ============================================================

typeperf -qx > "C:\Users\_____\Desktop\AvailableCounters.txt"
