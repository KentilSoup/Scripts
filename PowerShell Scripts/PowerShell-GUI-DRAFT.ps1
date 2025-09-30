# -----------------------------------------------
# PowerShell-GUI-DRAFT.ps1
# Created By: Kent Fulton
# Last Edited: 09-30-2025
# -----------------------------------------------
# This PowerShell script creates a GUI hub for launching various admin tools.
# Each button opens a new window that prompts for a server name and runs a selected script.
# Real-time output is displayed in a log box using a temporary file.
# Scripts are expected to be located in the user's profile under C:\Users\<User>\Scripts.
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

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

### MAIN HUB WINDOW ###
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "PowerShell GUI v1"
$mainForm.Size = New-Object System.Drawing.Size(400,550)
$mainForm.StartPosition = "CenterScreen"

# Heading Label
$headingLabel = New-Object System.Windows.Forms.Label
$headingLabel.Text = "PowerShell GUI v1"
$headingLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$headingLabel.AutoSize = $true
$mainForm.Controls.Add($headingLabel)
$mainForm.PerformLayout()
$mainForm.Refresh()
$headingLabel.Location = New-Object System.Drawing.Point(
    [math]::Max(0, ($mainForm.ClientSize.Width - $headingLabel.Width) / 2),
    10
)

# Button Definitions
$buttons = @(
    @{Text="Ping For Active Users"; Script="PingForActiveUsers.ps1"},
    @{Text="List Hardware Info"; Script="ListHardwareInfo.ps1"},
    @{Text="List Networking Info"; Script="ListNetworkingInfo.ps1"},
    @{Text="List AD Membership"; Script="ListADMembership.ps1"},
    @{Text="List Server Owners"; Script="ListServerOwners.ps1"},
    @{Text="List Installed Software"; Script="ListInstalledSoftware.ps1"},
    @{Text="List Installed Server Roles & Features"; Script="ListServerRolesFeatures.ps1"}
)

# Add Buttons to Main Form
$y = 50
foreach ($btn in $buttons) {
    $buttonText = $btn.Text
    $scriptName = $btn.Script

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $buttonText
    $button.Location = New-Object System.Drawing.Point(100, $y)
    $button.Size = New-Object System.Drawing.Size(200,40)

    $button.Add_Click({
        param($sender, $eventArgs)
        Show-ScriptWindow $scriptName $sender.Text
    })

    $mainForm.Controls.Add($button)
    $y += 50
}

# Exit Button
$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Exit"
$btnExit.Location = New-Object System.Drawing.Point(100, $y)
$btnExit.Size = New-Object System.Drawing.Size(200,40)
$btnExit.Add_Click({ $mainForm.Close() })
$mainForm.Controls.Add($btnExit)

### FUNCTION TO OPEN SCRIPT WINDOWS WITH REAL-TIME OUTPUT ###
function Show-ScriptWindow($scriptName, $windowTitle) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $windowTitle
    $form.Size = New-Object System.Drawing.Size(500,400)
    $form.StartPosition = "CenterScreen"

    # Input Label
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Enter Server Name:"
    $label.Location = New-Object System.Drawing.Point(20,20)
    $label.Size = New-Object System.Drawing.Size(300,20)
    $form.Controls.Add($label)

    # Input Box
    $inputBox = New-Object System.Windows.Forms.TextBox
    $inputBox.Location = New-Object System.Drawing.Point(20,45)
    $inputBox.Size = New-Object System.Drawing.Size(300,20)
    $form.Controls.Add($inputBox)

    # Log Box
    $logBox = New-Object System.Windows.Forms.TextBox
    $logBox.Location = New-Object System.Drawing.Point(20,120)
    $logBox.Size = New-Object System.Drawing.Size(440,200)
    $logBox.Multiline = $true
    $logBox.ScrollBars = "Vertical"
    $logBox.ReadOnly = $true
    $form.Controls.Add($logBox)

    # Run Button
    $runBtn = New-Object System.Windows.Forms.Button
    $runBtn.Text = "Run Script as Admin"
    $runBtn.Location = New-Object System.Drawing.Point(20,80)
    $runBtn.Size = New-Object System.Drawing.Size(200,30)
    $runBtn.Add_Click({
        $computername = $inputBox.Text
        $scriptPath = "$env:USERPROFILE\Scripts\$scriptName"
        $logPath = "$env:TEMP\gui_output.txt"

        if (Test-Path $logPath) { Remove-Item $logPath }

        $command = "powershell.exe -ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`" -computername `"$computername`""

        Start-Process powershell.exe -Verb RunAs -ArgumentList "-Command `"& { $command | Tee-Object -FilePath '$logPath' }`""

        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 1000
        $timer.Add_Tick({
            if (Test-Path $logPath) {
                $logBox.Text = Get-Content $logPath -Raw
            }
        })
        $timer.Start()
    })
    $form.Controls.Add($runBtn)

    $form.ShowDialog()
}

# Show the main hub
$mainForm.ShowDialog()
