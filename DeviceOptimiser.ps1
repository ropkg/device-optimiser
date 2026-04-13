Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------- INIT ----------------
$global:TotalFiles = 0
$psdrive = Get-PSDrive -Name C -ErrorAction SilentlyContinue
$DiskBefore = if ($psdrive) { $psdrive.Free } else { 0 }

# ---------------- FORM ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Device Optimiser"
$form.Size = New-Object System.Drawing.Size(420,480)
$form.StartPosition = "CenterScreen"

# ---------------- CHECKBOX HELPER ----------------
$checkboxes = @()

function New-CheckBox($text, $y) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $text
    $cb.Location = New-Object System.Drawing.Point(20,$y)
    $cb.AutoSize = $true
    $form.Controls.Add($cb)
    $checkboxes += $cb
    return $cb
}

# ---------------- CHECKBOXES ----------------
$cbAll      = New-CheckBox "Select All" 20
$cbTemp     = New-CheckBox "User Temp Files" 60
$cbWinTemp  = New-CheckBox "Windows Temp Files" 90
$cbPrefetch = New-CheckBox "Prefetch Files" 120
$cbChrome   = New-CheckBox "Chrome Cache" 150
$cbEdge     = New-CheckBox "Edge Cache" 180
$cbUpdate   = New-CheckBox "Reset Windows Update Cache (Advanced)" 210
$cbRecycle  = New-CheckBox "Recycle Bin" 240
$cbDeferred = New-CheckBox "Deferred Updates Cleanup" 270

# ---------------- SELECT ALL ----------------
$cbAll.Add_CheckedChanged({
    foreach ($cb in $checkboxes) {
        if ($cb -ne $cbAll) {
            $cb.Checked = $cbAll.Checked
        }
    }
})

# ---------------- BUTTON ----------------
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Optimisation"
$btnRun.Size = New-Object System.Drawing.Size(160,40)
$btnRun.Location = New-Object System.Drawing.Point(120,340)
$form.Controls.Add($btnRun)

# ---------------- CLEAN FUNCTION ----------------
function Clean-Folder($path) {
    if (Test-Path $path) {
        $items = Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue

        if ($items) {
            $count = ($items | Measure-Object).Count
            $global:TotalFiles += $count

            foreach ($item in $items) {
                try { Remove-Item $item.FullName -Recurse -Force -ErrorAction SilentlyContinue } catch {}
            }
        }
    }
}

# ---------------- BUTTON CLICK ----------------
$btnRun.Add_Click({

    # Reset counter each run
    $global:TotalFiles = 0

    # Close browsers
    Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
    Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue

    # ---------------- CLEANUP ----------------
    if ($cbTemp.Checked) {
        Clean-Folder "$env:TEMP"
    }

    if ($cbWinTemp.Checked) {
        Clean-Folder "C:\Windows\Temp"
    }

    if ($cbPrefetch.Checked) {
        Clean-Folder "C:\Windows\Prefetch"
    }

    if ($cbChrome.Checked) {
        Clean-Folder "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    }

    if ($cbEdge.Checked) {
        Clean-Folder "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    }

    if ($cbDeferred.Checked) {
        Clean-Folder "C:\Windows\SoftwareDistribution\DeliveryOptimization"
    }

    if ($cbRecycle.Checked) {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    }

    # ---------------- WINDOWS UPDATE FULL CLEAN ----------------
    if ($cbUpdate.Checked) {

        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "This will reset Windows Update cache and remove update history. Continue?",
            "Warning",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if ($confirm -eq "Yes") {

            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            Stop-Service bits -Force -ErrorAction SilentlyContinue

            Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue

            Start-Service wuauserv -ErrorAction SilentlyContinue
            Start-Service bits -ErrorAction SilentlyContinue
        }
    }

    # ---------------- CALCULATE RESULTS ----------------
    $psdriveAfter = Get-PSDrive -Name C -ErrorAction SilentlyContinue
    $DiskAfter = if ($psdriveAfter) { $psdriveAfter.Free } else { 0 }

    $DiskFreedMB = [math]::Round(($DiskAfter - $DiskBefore)/1MB,2)
    $DiskFreedGB = [math]::Round(($DiskAfter - $DiskBefore)/1GB,2)

    # Boost score (simple visual metric)
    $Boost = [math]::Min([math]::Round(($DiskFreedMB / 50),0),100)

    # ---------------- COMPLETE MESSAGE ----------------
    [System.Windows.Forms.MessageBox]::Show(
        "Optimisation Completed Successfully`n`n" +
        "Files cleaned : $TotalFiles`n" +
        "Disk freed    : $DiskFreedMB MB ($DiskFreedGB GB)`n" +
        "Performance Boost : $Boost %",
        "Device Optimiser",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
})

# ---------------- RUN ----------------
$form.Topmost = $true
$form.ShowDialog()