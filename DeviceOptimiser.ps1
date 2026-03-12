Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "        Windows Device Optimiser         "
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$DiskBefore = (Get-PSDrive C).Free
$TotalFiles = 0

function Clean-Folder {
    param ($Path)

    if (Test-Path $Path) {
        $files = Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue
        $count = $files.Count
        $global:TotalFiles += $count

        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Cleaned: $Path"
        Write-Host "Files removed: $count"
        Write-Host ""
    }
}

Write-Host "Starting cleanup..." -ForegroundColor Yellow
Write-Host ""

# Close Chrome if running
$chrome = Get-Process chrome -ErrorAction SilentlyContinue
if ($chrome) {
    Write-Host "Closing Google Chrome..." -ForegroundColor Yellow
    Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
}

# Close Edge if running
$edge = Get-Process msedge -ErrorAction SilentlyContinue
if ($edge) {
    Write-Host "Closing Microsoft Edge..." -ForegroundColor Yellow
    Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue
}

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

# Windows Update Cache
Write-Host "Cleaning Windows Update Cache..."

Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Clean-Folder "C:\Windows\SoftwareDistribution\Download\*"
Start-Service wuauserv -ErrorAction SilentlyContinue

# Recycle Bin
Write-Host "Cleaning Recycle Bin..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

$DiskAfter = (Get-PSDrive C).Free
$Recovered = ($DiskAfter - $DiskBefore) / 1GB

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Cleanup Completed"
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Total files processed: $TotalFiles"
Write-Host "Disk space recovered: $([math]::Round($Recovered,2)) GB"