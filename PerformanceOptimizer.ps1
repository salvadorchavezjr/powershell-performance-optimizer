
# ==============================================
# MSSA Project 3 - Windows Performance Optimizer
# Version 2.0
# ==============================================

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       WINDOWS PERFORMANCE OPTIMIZER     " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1. View System Performance"
    Write-Host "2. View Resource-Heavy Processes"
    Write-Host "3. Analyze Disk Space"
    Write-Host "4. Analyze and Clean Temporary Files"
    Write-Host "5. View Startup Applications"
    Write-Host "6. Generate Performance Report"
    Write-Host "7. Exit"
    Write-Host ""
}

# OPTION 1: CPU, memory and uptime
function Show-SystemPerformance {
    Write-Host "`n=== SYSTEM PERFORMANCE ===" -ForegroundColor Yellow

    try {
        $OS = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $CPU = @(Get-CimInstance Win32_Processor -ErrorAction Stop)

        $CPULoad = $CPU |
            Where-Object { $null -ne $_.LoadPercentage } |
            Measure-Object -Property LoadPercentage -Average

        $CPUUsage = if ($CPULoad.Count -gt 0) {
            [math]::Round($CPULoad.Average, 1)
        } else {
            "Unavailable"
        }

        $TotalRAM = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
        $FreeRAM = [math]::Round($OS.FreePhysicalMemory / 1MB, 2)
        $UsedRAM = [math]::Round($TotalRAM - $FreeRAM, 2)
        $RAMPercent = [math]::Round(
            (1 - $OS.FreePhysicalMemory / $OS.TotalVisibleMemorySize) * 100, 1
        )

        $Uptime = (Get-Date) - $OS.LastBootUpTime

        Write-Host "Computer: $env:COMPUTERNAME"
        Write-Host "Operating System: $($OS.Caption)"
        Write-Host "CPU Load (approx.): $CPUUsage%"
        Write-Host "Total RAM: $TotalRAM GB"
        Write-Host "Used RAM: $UsedRAM GB"
        Write-Host "Available RAM: $FreeRAM GB"
        Write-Host "RAM Usage: $RAMPercent%"
        Write-Host "Uptime: $($Uptime.Days) days, $($Uptime.Hours) hours"

        if ($RAMPercent -ge 90) {
            Write-Warning "High memory usage detected."
        }
    }
    catch {
        Write-Host "Performance check failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# OPTION 2: Top memory-consuming processes
function Show-HeavyProcesses {
    Write-Host "`n=== TOP 10 MEMORY-CONSUMING PROCESSES ===" -ForegroundColor Yellow

    try {
        Get-Process -ErrorAction Stop |
            Sort-Object WorkingSet64 -Descending |
            Select-Object -First 10 ProcessName, Id,
                @{Name="MemoryMB";Expression={
                    [math]::Round($_.WorkingSet64 / 1MB, 2)
                }},
                @{Name="CPUTimeSeconds";Expression={
                    if ($null -ne $_.CPU) {
                        [math]::Round($_.CPU, 1)
                    }
                }} |
            Format-Table -AutoSize

        Write-Host "CPUTimeSeconds is total CPU time, not current CPU percentage." -ForegroundColor Gray
    }
    catch {
        Write-Host "Process analysis failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# OPTION 3: Storage analysis
function Show-DiskHealth {
    Write-Host "`n=== DISK SPACE ANALYSIS ===" -ForegroundColor Yellow

    try {
        $Disks = Get-CimInstance Win32_LogicalDisk `
            -Filter "DriveType=3" -ErrorAction Stop

        foreach ($Disk in $Disks) {
            if ($Disk.Size -le 0) { continue }

            $TotalGB = [math]::Round($Disk.Size / 1GB, 2)
            $FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
            $FreePercent = [math]::Round(
                ($Disk.FreeSpace / $Disk.Size) * 100, 1
            )

            Write-Host "`nDrive: $($Disk.DeviceID)"
            Write-Host "Total: $TotalGB GB"
            Write-Host "Free: $FreeGB GB ($FreePercent%)"

            if ($FreePercent -lt 15) {
                Write-Warning "Low storage space."
            }
            else {
                Write-Host "Storage status: OK" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "Storage analysis failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# OPTION 4: Preview and optionally clean old temp files
function Start-TempCleanup {
    Write-Host "`n=== TEMPORARY FILE ANALYSIS ===" -ForegroundColor Yellow

    # Only use the current user's temp folder
    $TempPath = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')
    $Cutoff = (Get-Date).AddDays(-7)

    Write-Host "Folder: $TempPath"
    Write-Host "Checking files older than 7 days..."

    try {
        # Only top-level files; skip directories and reparse points
        $Files = @(
            Get-ChildItem -LiteralPath $TempPath -File -Force `
                -ErrorAction Stop |
                Where-Object {
                    $_.LastWriteTime -lt $Cutoff -and
                    -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
                }
        )

        if ($Files.Count -eq 0) {
            Write-Host "No eligible temporary files found." -ForegroundColor Green
            return
        }

        $TotalBytes = ($Files | Measure-Object Length -Sum).Sum
        $TotalMB = [math]::Round($TotalBytes / 1MB, 2)

        Write-Host "`nEligible files: $($Files.Count)"
        Write-Host "Potential space savings: $TotalMB MB"
        Write-Host "No files have been deleted." -ForegroundColor Cyan

        $Confirm = Read-Host "Delete these old top-level temp files? (YES/NO)"

        if ($Confirm -cne "YES") {
            Write-Host "Cleanup cancelled. No files deleted." -ForegroundColor Yellow
            return
        }

        $Deleted = 0
        $Failed = 0
        $FreedBytes = 0

        foreach ($File in $Files) {
            try {
                # Check again before deleting
                $Current = Get-Item -LiteralPath $File.FullName `
                    -Force -ErrorAction Stop

                if ($Current.PSIsContainer -or
                    $Current.LastWriteTime -ge $Cutoff -or
                    ($Current.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                    continue
                }

                Remove-Item -LiteralPath $Current.FullName `
                    -Force -ErrorAction Stop

                $Deleted++
                $FreedBytes += $Current.Length
            }
            catch {
                $Failed++
            }
        }

        Write-Host "`n=== CLEANUP RESULTS ===" -ForegroundColor Cyan
        Write-Host "Files deleted: $Deleted"
        Write-Host "Files skipped due to errors: $Failed"
        Write-Host "Approximate space freed: $([math]::Round($FreedBytes / 1MB, 2)) MB"
        Write-Host "Subfolders were not modified." -ForegroundColor Green
    }
    catch {
        Write-Host "Temp analysis failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# OPTION 5: Startup application analysis
function Show-StartupApps {
    Write-Host "`n=== STARTUP APPLICATIONS ===" -ForegroundColor Yellow

    try {
        Get-CimInstance Win32_StartupCommand -ErrorAction Stop |
            Select-Object Name, Location, User, Command |
            Format-Table -Wrap
    }
    catch {
        Write-Host "Startup analysis failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`nThis is an inventory only. No startup settings were changed." -ForegroundColor Gray
}

# OPTION 6: Generate a CSV report
function Export-PerformanceReport {
    Write-Host "`n=== GENERATING PERFORMANCE REPORT ===" -ForegroundColor Yellow

    try {
        $OS = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $CPU = @(Get-CimInstance Win32_Processor -ErrorAction Stop)

        $CPULoad = $CPU |
            Where-Object { $null -ne $_.LoadPercentage } |
            Measure-Object -Property LoadPercentage -Average

        $CPUUsage = if ($CPULoad.Count -gt 0) {
            [math]::Round($CPULoad.Average, 1)
        } else {
            $null
        }

        $MemoryPercent = [math]::Round(
            (1 - $OS.FreePhysicalMemory / $OS.TotalVisibleMemorySize) * 100, 1
        )

        $Disks = @(Get-CimInstance Win32_LogicalDisk `
            -Filter "DriveType=3" -ErrorAction Stop)

        $ReportFolder = Join-Path $PSScriptRoot "Reports"

        New-Item -ItemType Directory -Path $ReportFolder `
            -Force -ErrorAction Stop | Out-Null

        $Report = foreach ($Disk in $Disks) {
            if ($Disk.Size -le 0) { continue }

            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                OperatingSystem = $OS.Caption
                CPUUsagePercent = $CPUUsage
                MemoryUsagePercent = $MemoryPercent
                Drive = $Disk.DeviceID
                TotalDiskGB = [math]::Round($Disk.Size / 1GB, 2)
                FreeDiskGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
            }
        }

        if (-not $Report) {
            Write-Host "No suitable disks found for the report." -ForegroundColor Yellow
            return
        }

        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $ReportPath = Join-Path $ReportFolder "Performance_$Timestamp.csv"

        $Report | Export-Csv -LiteralPath $ReportPath `
            -NoTypeInformation -Encoding UTF8 -ErrorAction Stop

        Write-Host "Report generated successfully!" -ForegroundColor Green
        Write-Host "Saved to: $ReportPath"
    }
    catch {
        Write-Host "Report generation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# MAIN APPLICATION LOOP
do {
    Show-Menu
    $Choice = Read-Host "Choose an option (1-7)"

    switch ($Choice) {
        "1" { Show-SystemPerformance }
        "2" { Show-HeavyProcesses }
        "3" { Show-DiskHealth }
        "4" { Start-TempCleanup }
        "5" { Show-StartupApps }
        "6" { Export-PerformanceReport }
        "7" {
            Write-Host "Exiting Performance Optimizer..." -ForegroundColor Green
        }
        default {
            Write-Host "Invalid selection. Choose 1-7." -ForegroundColor Red
        }
    }

    if ($Choice -ne "7") {
        Read-Host "`nPress Enter to return to the menu"
    }

} while ($Choice -ne "7")
