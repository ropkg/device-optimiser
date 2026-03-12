Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "        Windows Device Optimiser         " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get disk space before cleanup
$DiskBefore = (Get-PSDrive C).Free
$TotalFiles = 0

Write-Host "Starting system cleanup..." -ForegroundColor Yellow
Write-Host ""

# Locations to clean
$Paths = @(
    "$env:TEMP\*",
    "C:\Windows\Temp\*",
    "C:\Windows\Prefetch\*"
)

foreach ($Path in $Paths) {

    if (Test-Path $Path) {

        Write-Host "Cleaning: $Path"

        $Files = Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue

        $Count = $Files.Count
        $TotalFiles += $Count

        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "$Count files removed"
        Write-Host ""
    }
}

# Clear Recycle Bin
Write-Host "Cleaning Recycle Bin..."
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Host "Recycle bin cleanup skipped"
}

# Disk space after cleanup
$DiskAfter = (Get-PSDrive C).Free
$SpaceRecovered = ($DiskAfter - $DiskBefore) / 1GB

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Cleanup Completed!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

Write-Host ""
Write-Host "Total files processed: $TotalFiles"
Write-Host "Disk space recovered: $([math]::Round($SpaceRecovered,2)) GB"
Write-Host ""

Write-Host "Device optimisation completed successfully." -ForegroundColor Cyan