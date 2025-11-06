# -----------------------------------------------
# Spinning-Cube-3D-v1.ps1
# Created By: Kent Fulton
# Enhanced Version: 11-06-2025
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

# Function to safely get console size
function Get-ConsoleSize {
    try {
        $width = [console]::WindowWidth
        $height = [console]::WindowHeight
    } catch {
        $width = 80
        $height = 25
    }
    return @($width, $height)
}

# Function to project a 3D point to 2D
function Project-Point {
    param($x, $y, $z, $angleX, $angleY, $width, $height)

    # Rotate X
    $cosX = [math]::Cos($angleX)
    $sinX = [math]::Sin($angleX)
    $yNew = $y * $cosX - $z * $sinX
    $zNew = $y * $sinX + $z * $cosX

    # Rotate Y
    $cosY = [math]::Cos($angleY)
    $sinY = [math]::Sin($angleY)
    $xNew = $x * $cosY + $zNew * $sinY
    $zFinal = -$x * $sinY + $zNew * $cosY

    # Perspective projection
    $distance = 5
    $scaleX = ($width / 2) * 0.8
    $scaleY = ($height / 2) * 0.8
    $factorX = $scaleX / ($distance + $zFinal)
    $factorY = $scaleY / ($distance + $zFinal)

    # Aspect ratio correction
    $aspectRatio = 1.8
    $xProj = [int]($xNew * $factorX + $width / 2)
    $yProj = [int]($yNew * $factorY * $aspectRatio + $height / 2)

    return @($xProj, $yProj, $zFinal)
}

# Function to draw a line using Bresenham algorithm
function Draw-Line {
    param($x1, $y1, $x2, $y2, [ref]$screen, $char)
    $dx = [math]::Abs($x2 - $x1)
    $dy = [math]::Abs($y2 - $y1)
    $sx = if ($x1 -lt $x2) {1} else {-1}
    $sy = if ($y1 -lt $y2) {1} else {-1}
    $err = $dx - $dy

    while ($true) {
        if ($y1 -ge 0 -and $y1 -lt $screen.Value.Count -and $x1 -ge 0 -and $x1 -lt $screen.Value[0].Length) {
            $line = $screen.Value[$y1].ToCharArray()
            $line[$x1] = $char
            $screen.Value[$y1] = -join $line
        }
        if ($x1 -eq $x2 -and $y1 -eq $y2) { break }
        $e2 = 2 * $err
        if ($e2 -gt -$dy) { $err -= $dy; $x1 += $sx }
        if ($e2 -lt $dx) { $err += $dx; $y1 += $sy }
    }
}

# Function to draw the cube
function Draw-Cube {
    param($angleX, $angleY)

    $size = Get-ConsoleSize
    $width = $size[0]; $height = $size[1]

    $vertices = @(
        @(-1, -1, -1), @(1, -1, -1), @(1, 1, -1), @(-1, 1, -1),
        @(-1, -1, 1),  @(1, -1, 1),  @(1, 1, 1),  @(-1, 1, 1)
    )

    $edges = @(
        @(0,1), @(1,2), @(2,3), @(3,0),
        @(4,5), @(5,6), @(6,7), @(7,4),
        @(0,4), @(1,5), @(2,6), @(3,7)
    )

    $screen = @()
    for ($i=0; $i -lt $height; $i++) { $screen += (" " * $width) }

    $projected = @()
    foreach ($v in $vertices) { $projected += ,(Project-Point $v[0] $v[1] $v[2] $angleX $angleY $width $height) }

    foreach ($edge in $edges) {
        $p1 = $projected[$edge[0]]; $p2 = $projected[$edge[1]]
        Draw-Line $p1[0] $p1[1] $p2[0] $p2[1] ([ref]$screen) '■'
    }

    # Clear console and render
    Clear-Host
    foreach ($row in $screen) {
        Write-Host $row
    }
}

# Hide cursor
try { [console]::CursorVisible = $false } catch {}

try {
    $angle = 0.0
    while ($true) {
        Draw-Cube $angle ($angle / 2)
        $angle += 0.05
        Start-Sleep -Milliseconds 30
    }
}
finally {
    try { [console]::CursorVisible = $true } catch {}
}
