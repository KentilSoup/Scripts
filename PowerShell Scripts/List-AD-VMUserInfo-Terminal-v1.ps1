# -----------------------------------------------
# List-AD-VMUserInfo-Terminal-v1.ps1
# Created By: Kent Fulton
# Last Edited: 10-02-2025
# -----------------------------------------------
# Description:
# This script connects to a specified VM and performs the following:
# - Retrieves active user sessions with login times, idle times, and session durations
# - Identifies the last signed-in user and queries Active Directory for detailed user info
# - Queries AD for each active user to collect:
#     Display Name, Username, Email, Phone, Department,
#     Job Title, Manager, Street, City, State, Zip, OU
# - Retrieves the computer's OU location from AD
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

param (
    [string]$VMName = "Computer You Want To Target"
)

clear

function Get-ActiveSessions {
    Invoke-Command -ComputerName $VMName -ScriptBlock {
        $currentTime = Get-Date
        query user | Where-Object { $_ -notmatch "USERNAME|SESSIONNAME" } | ForEach-Object {
            $parts = ($_ -replace '[><*]', '' -split '\s{2,}').Trim()
            $logonTime = $parts[4]
            $sessionTime = ""

            if ($logonTime -and ($parsedLogonTime = [datetime]::Parse($logonTime))) {
                $sessionTime = ($currentTime - $parsedLogonTime).ToString("hh\:mm\:ss")
            }

            [PSCustomObject]@{
                Username    = $parts[0]
                SessionID   = $parts[1]
                State       = $parts[2]
                IdleTime    = $parts[3]
                LogonTime   = $logonTime
                SessionTime = $sessionTime
            }
        }
    } -ErrorAction SilentlyContinue
}

function Get-ADUserDetails {
    param ($Username)
    $cleanUser = $Username.Trim().ToUpper()
    try {
        $user = Get-ADUser -Filter "SamAccountName -eq '$cleanUser'" -Properties DisplayName, EmailAddress, TelephoneNumber, Department, Title, Manager, StreetAddress, City, State, PostalCode, DistinguishedName
        if ($user) {
            $managerName = ""
            if ($user.Manager) {
                $managerName = (Get-ADUser $user.Manager -Properties DisplayName).DisplayName
            }

            $ouPath = ($user.DistinguishedName -split ',(?=OU=)') -join ','

            return [PSCustomObject]@{
                DisplayName = $user.DisplayName
                Username    = $user.SamAccountName
                Email       = $user.EmailAddress
                Phone       = $user.TelephoneNumber
                Department  = $user.Department
                JobTitle    = $user.Title
                Manager     = $managerName
                Street      = $user.StreetAddress
                City        = $user.City
                State       = $user.State
                Zip         = $user.PostalCode
                OU          = $ouPath
            }
        } else {
            Write-Warning "User ${cleanUser} not found in AD."
        }
    } catch {
        Write-Warning "AD lookup failed for ${Username}: $_"
    }
}

function Get-ComputerOU {
    param ($ComputerName)
    try {
        $computer = Get-ADComputer -Identity $ComputerName -Properties DistinguishedName
        if ($computer) {
            $ouPath = ($computer.DistinguishedName -split ',(?=OU=)') -join ','
            return $ouPath
        } else {
            Write-Warning "Computer ${ComputerName} not found in AD."
        }
    } catch {
        Write-Warning "AD lookup failed for computer ${ComputerName}: $_"
    }
}

function Get-UserFolders {
    Invoke-Command -ComputerName $VMName -ScriptBlock {
        $userFolders = Get-ChildItem -Path "C:\Users" -Directory -ErrorAction SilentlyContinue
        $folderInfo = @()

        foreach ($folder in $userFolders) {
            if (Test-Path $folder.FullName) {
                try {
                    $sizeBytes = (Get-ChildItem -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    $sizeMB = [math]::Round($sizeBytes / 1MB, 2)
                    $sizeGB = [math]::Round($sizeBytes / 1GB, 2)

                    $folderInfo += [PSCustomObject]@{
                        FolderName   = $folder.Name
                        LastModified = $folder.LastWriteTime
                        SizeMB       = $sizeMB
                        SizeGB       = $sizeGB
                        FullPath     = $folder.FullName
                    }
                } catch {
                    Write-Warning "Failed to calculate size for folder: $($folder.FullName)"
                }
            }
        }

        $folderInfo | Sort-Object SizeGB -Descending
    } -ErrorAction Stop
}

Write-Host "`nConnecting to $VMName..."

# Computer OU Location
$computerOU = Get-ComputerOU -ComputerName $VMName
if ($computerOU) {
    Write-Host "`nComputer OU Location:"
    Write-Host "------------------------"
    Write-Host $computerOU
}

# Active Sessions
Write-Host "`nActive User Sessions:"
$activeSessions = Get-ActiveSessions
if ($activeSessions) {
    foreach ($session in $activeSessions) {
        Write-Host "----------------------------------------------"
        Write-Host "Username:    $($session.Username)"
        Write-Host "Session ID:  $($session.SessionID)"
        Write-Host "State:       $($session.State)"
        Write-Host "IdleTime:    $($session.IdleTime)"
        Write-Host "LogonTime:   $($session.LogonTime)"
        Write-Host "SessionTime: $($session.SessionTime)"
        Write-Host "----------------------------------------------`n"
    }
} else {
    Write-Host "No active sessions found."
}

# Last Signed-In User with AD Info
$lastUser = Get-LastSignedInUser
if ($lastUser) {
    $cleanUser = $lastUser -replace '^.+\\', ''
    $adInfo = Get-ADUserDetails -Username $cleanUser
    if ($adInfo) {
        Write-Host "`nLast Signed-In User AD Info:"
        Write-Host "-------------------------------------------"
        Write-Host "DisplayName: $($adInfo.DisplayName)"
        Write-Host "Username:    $($adInfo.Username)"
        Write-Host "Email:       $($adInfo.Email)"
        Write-Host "Phone:       $($adInfo.Phone)"
        Write-Host "Department:  $($adInfo.Department)"
        Write-Host "Job Title:   $($adInfo.JobTitle)"
        Write-Host "Manager:     $($adInfo.Manager)"
        Write-Host "Street:      $($adInfo.Street)"
        Write-Host "City:        $($adInfo.City)"
        Write-Host "State:       $($adInfo.State)"
        Write-Host "OU:          $($adInfo.OU)"
        Write-Host "-------------------------------------------"
    }
}

# AD Info for Active Users
Write-Host "`nRetrieving AD Info for Active Users..."
$adResults = @()
foreach ($session in $activeSessions) {
    $username = $session.Username
    if ($username -and $username -ne "USERNAME") {
        $details = Get-ADUserDetails -Username $username
        if ($details) { $adResults += $details }
    }
}

if ($adResults.Count -gt 0) {
    foreach ($user in $adResults) {
        Write-Host "-------------------------------------------"
        Write-Host "DisplayName: $($user.DisplayName)"
        Write-Host "Username:    $($user.Username)"
        Write-Host "Email:       $($user.Email)"
        Write-Host "Phone:       $($user.Phone)"
        Write-Host "Department:  $($user.Department)"
        Write-Host "Job Title:   $($user.JobTitle)"
        Write-Host "Manager:     $($user.Manager)"
        Write-Host "Street:      $($user.Street)"
        Write-Host "City:        $($user.City)"
        Write-Host "State:       $($user.State)"
        Write-Host "OU:          $($user.OU)"
        Write-Host "-------------------------------------------"
    }
} else {
    Write-Host "No AD details found for active users."
}

# Last Signed In User:

Write-Host "`nLast Signed In User:"
Write-Host "-------------------------------------------"

$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"

try {
    $lastUser = Invoke-Command -ComputerName $VMName -ScriptBlock {
        param ($path)
        try {
            $userInfo = Get-ItemProperty -Path $path -Name LastLoggedOnUser -ErrorAction Stop
            return $userInfo.LastLoggedOnUser
        }
        catch {
            Write-Error "Registry key not found or inaccessible."
        }
    } -ArgumentList $regPath

    if ($lastUser) {
        Write-Host ("Last signed-in user on {0}: {1}" -f $VMName, $lastUser)

        # Extract domain and username
        $domain, $samAccount = $lastUser -split '\\'

        # Get AD user details
        $user = Get-ADUser -Identity $samAccount -Properties DisplayName, EmailAddress, TelephoneNumber, Department, Title, Manager, StreetAddress, City, State, PostalCode, DistinguishedName

        # Get Manager's name
        $managerName = if ($user.Manager) {
            (Get-ADUser -Identity $user.Manager).DisplayName
        } else {
            "N/A"
        }

        # Get OU path
        $ouPath = ($user.DistinguishedName -split ',(?=OU=)')[-1]

        # Display user details
        Write-Host "DisplayName : $($user.DisplayName)"
        Write-Host "Username    : $($user.SamAccountName)"
        Write-Host "Email       : $($user.EmailAddress)"
        Write-Host "Phone       : $($user.TelephoneNumber)"
        Write-Host "Department  : $($user.Department)"
        Write-Host "JobTitle    : $($user.Title)"
        Write-Host "Manager     : $managerName"
        Write-Host "Street      : $($user.StreetAddress)"
        Write-Host "City        : $($user.City)"
        Write-Host "State       : $($user.State)"
        Write-Host "Zip         : $($user.PostalCode)"
        Write-Host "OU          : $ouPath"
        Write-Host "-------------------------------------------"

    } else {
        Write-Warning "No user information found on $VMName."
    }
}
catch {
    Write-Warning "Failed to retrieve last signed-in user from $VMName. $_"
}

# User Folders Info
Write-Host "`nUser Folders on $VMName (Sorted by Largest Size):"
$userFolders = Get-UserFolders
if ($userFolders) {
    foreach ($folder in $userFolders) {
        Write-Host "-------------------------------------------"
        Write-Host "Folder Name:   $($folder.FolderName)"
        Write-Host "Last Modified: $($folder.LastModified)"
        Write-Host "Size (MB):     $($folder.SizeMB)"
        Write-Host "Size (GB):     $($folder.SizeGB)"
        Write-Host "Path:          $($folder.FullPath)"
        Write-Host "-------------------------------------------"
    }
} else {
    Write-Host "No user folders found under C:\Users."
}
