# =================================================================
# PowerShell Script: Export-TLS-Ciphers-Text-v1.ps1
# Author: Kent Fulton
# Last Edited: 10-10-2025
# =================================================================
# Make sure the module is installed before running: 
#   - Install-Module -Name PSnmap -Scope CurrentUser
#   - Import-Module PSnmap
# =================================================================
# Description:
# Scans a specific host for TLS/SSL configurations.
# Targets a custom list of ports (e.g., 443, 3389, 8443, etc.).
# Uses the ssl-enum-ciphers script to:
#    - List supported TLS versions.
#    - Show available cipher suites.
#    - Identify weak or outdated encryption.
# Saves results in TXT format.
# =================================================================
# DISCLAIMER: See LICENSE and DISCLAIMER.md in the root of this repository.
# =================================================================
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
# =================================================================

nmap -p 21,25,83,84,110,143,442,443,444,465,587,636,990,993,995,1433,1636,1993,1995,3269,3389,4443,4444,4903,5000,5001,5556,5558,5900,6143,6969,7002,7006,7789,8000,8002,8080,8082,8443,9002,9043,9443,10000 -oX tls_nmap.xml --script ssl-enum-ciphers HOSTNAME -oX "C:\Users\username\Downloads\HOSTNAME.txt"
