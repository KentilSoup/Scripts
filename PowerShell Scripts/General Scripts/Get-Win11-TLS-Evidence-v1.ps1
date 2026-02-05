# ------------------------------------------------------------
# Get-Win11-TLS-Evidence.ps1
# Created By: Kent Fulton
# Last Edited: 02-05-2026
# ------------------------------------------------------------
# Purpose: Collects simple, audit-ready evidence from a Win11 VM:
#   - OS info (confirms Windows 11 / modern TLS posture)
#   - Sample TLS cipher suites available (shows TLS 1.2/1.3 support)
#   - RDP listener check (confirms encrypted remote access port)
# Output: Saves a timestamped text file to the user's Downloads folder.
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

# Timestamp for the evidence file name
$ts = (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')

# Output file path in the user's Downloads folder
$out = "$env:USERPROFILE\Downloads\Win11_TLS_Evidence_$ts.txt"

# Start the evidence file with a header + timestamp
"# Windows 11 TLS Evidence ($ts)" | Out-File $out

# ---- OS information (proves it's Windows 11 / modern OS) ----
"== OS Info ==" | Tee-Object -FilePath $out -Append
Get-ComputerInfo |
  Select-Object OsName, OsVersion, OsBuildNumber, WindowsProductName |
  Tee-Object -FilePath $out -Append

# ---- TLS cipher suite sample (shows modern TLS 1.2/1.3 ciphers exist) ----
"`n== TLS Cipher Suite sample ==" | Tee-Object -FilePath $out -Append
Get-TlsCipherSuite |
  Select-Object -First 10 |
  Tee-Object -FilePath $out -Append

# ---- RDP listener check (confirms encrypted remote access port is active) ----
"`n== RDP listener check (TCP/3389) ==" | Tee-Object -FilePath $out -Append
Test-NetConnection -ComputerName $env:COMPUTERNAME -Port 3389 |
  Tee-Object -FilePath $out -Append

# Final line showing where the evidence was saved
"Saved: $out"
