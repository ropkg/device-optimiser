Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "        Windows Device Optimiser         "
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure we're running on Windows
if (-not $IsWindows) {
    Write-Host "This script is intended to run on Windows PowerShell. Exiting." -ForegroundColor Red
    exit 1
}

# ---------------- DEVICE REPORTING ----------------

$device = @{
    computerName = $env:COMPUTERNAME
    username = $env:USERNAME
    os = (Get-CimInstance Win32_OperatingSystem).Caption
    version = "1.0"
}

$json = $device | ConvertTo-Json

try {
    Invoke-RestMethod `
        -Uri "https://device-optimiser-server.onrender.com" `
        -Method POST `
        -Body $json `
        -ContentType "application/json"
}
catch {
    Write-Host "Device reporting failed (server unavailable)" -ForegroundColor Yellow
}

# ---------------------------------------------------

$psdrive = Get-PSDrive -Name C -ErrorAction SilentlyContinue
if ($psdrive) {
    $DiskBefore = $psdrive.Free
}
else {
    $DiskBefore = 0
}
$TotalFiles = 0

function Clean-Folder {
    param ($Path)

    # Expand the path into items and remove them individually. This avoids issues with
    # wildcard paths and Null results from Get-ChildItem.
    $items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue

    # If there are no items, try to see if the path itself exists (for paths without wildcards)
    if (-not $items) {
        if (Test-Path $Path) {
            $items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue
        }
    }

    $count = 0
    if ($items) {
        # Count files and directories
        $count = ($items | Measure-Object).Count

        foreach ($it in $items) {
            try {
                Remove-Item -LiteralPath $it.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
            catch {
                # ignore individual remove errors
            }
        }

        $global:TotalFiles += $count
    }

    Write-Host "Cleaned: $Path"
    Write-Host "Files removed: $count"
    Write-Host ""
}

Write-Host "Starting cleanup..." -ForegroundColor Yellow
Write-Host ""

# ---------------- CLOSE BROWSERS ----------------

$chrome = Get-Process chrome -ErrorAction SilentlyContinue
if ($chrome) {
    Write-Host "Closing Google Chrome..." -ForegroundColor Yellow
    Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
}

$edge = Get-Process msedge -ErrorAction SilentlyContinue
if ($edge) {
    Write-Host "Closing Microsoft Edge..." -ForegroundColor Yellow
    Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue
}

# ------------------------------------------------

# User Temp
Clean-Folder "$env:TEMP\*"

# Windows Temp
Clean-Folder "C:\Windows\Temp\*"

# Prefetch
Clean-Folder "C:\Windows\Prefetch\*"

# Chrome Cache
Clean-Folder "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*"

# Edge Cache
Clean-Folder "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*"

# ---------------- WINDOWS UPDATE CACHE ----------------

Write-Host "Cleaning Windows Update Cache..."

Stop-Service wuauserv -Force -ErrorAction SilentlyContinue

Clean-Folder "C:\Windows\SoftwareDistribution\Download\*"

Start-Service wuauserv -ErrorAction SilentlyContinue

# ------------------------------------------------------

# Recycle Bin
Write-Host "Cleaning Recycle Bin..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# ---------------- FINAL REPORT ----------------

$DiskAfter = (Get-PSDrive C).Free
$Recovered = ($DiskAfter - $DiskBefore) / 1GB

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Cleanup Completed"
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Total files processed: $TotalFiles"
Write-Host "Disk space recovered: $([math]::Round($Recovered,2)) GB"