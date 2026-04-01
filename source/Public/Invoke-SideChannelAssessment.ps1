function Invoke-SideChannelAssessment
{
    <#
    .SYNOPSIS
        Assess and manage Windows side-channel vulnerability mitigations.

    .DESCRIPTION
        Enterprise-grade function for assessing and managing Windows side-channel
        vulnerability mitigations (Spectre, Meltdown, L1TF, MDS, and related CVEs).

        Supports multiple operation modes:
        - Assess: Evaluate current security posture (default)
        - ApplyInteractive: Interactively select and apply mitigations
        - Revert: Quick restore of most recent backup
        - Backup: Create a manual configuration backup
        - RestoreInteractive: Browse backups and selectively restore

    .PARAMETER Mode
        Operation mode. Valid values: Assess, ApplyInteractive, Revert, Backup, RestoreInteractive.

    .PARAMETER ShowDetails
        Display detailed technical information including CVE numbers, descriptions, and URLs.

    .PARAMETER ExportPath
        Destination folder path where assessment results will be exported as CSV.
        The CSV filename is generated automatically using the pattern:
        SideChannelAssessment_<ComputerName>_<yyyyMMdd_HHmmss>.csv

    .PARAMETER LogPath
        Destination folder path where operation logs will be written.
        The log filename is generated automatically using the pattern:
        SideChannelCheck_<yyyyMMdd_HHmmss>.log

    .PARAMETER BackupPath
        Path where backup files are stored. Defaults to module Backups directory.

    .PARAMETER ConfigPath
        Path where configuration files are stored. Defaults to module Config directory.

    .EXAMPLE
        Invoke-SideChannelAssessment

        Run assessment and display current mitigation status.

    .EXAMPLE
        Invoke-SideChannelAssessment -Mode ApplyInteractive -WhatIf

        Preview mitigation changes without applying them.

    .EXAMPLE
        Invoke-SideChannelAssessment -ShowDetails -ExportPath 'C:\Reports'

        Run detailed assessment and export results as CSV to C:\Reports.

    .EXAMPLE
        Invoke-SideChannelAssessment -Mode Revert

        Quickly restore most recent backup.

    .NOTES
        Requires Administrator privileges and Windows 10/11 or Windows Server 2016+.
        Compatible with PowerShell 5.1 and 7.x.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Assess', SupportsShouldProcess)]
    param(
        [Parameter()]
        [ValidateSet('Assess', 'ApplyInteractive', 'Revert', 'Backup', 'RestoreInteractive')]
        [string]$Mode = 'Assess',

        [Parameter()]
        [switch]$ShowDetails,

        [Parameter()]
        [string]$ExportPath,

        [Parameter()]
        [string]$LogPath,

        [Parameter()]
        [string]$BackupPath,

        [Parameter()]
        [string]$ConfigPath
    )

    # Set module-scoped paths from parameters or defaults
    $logFileName = "SideChannelCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

    if ($LogPath) {
        $script:LogPath = Join-Path $LogPath $logFileName
    } else {
        $logsDir = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'Logs'
        if (-not (Test-Path $logsDir)) {
            $logsDir = Join-Path ([System.IO.Path]::GetTempPath()) 'SideChannelCheck'
        }
        $script:LogPath = Join-Path $logsDir $logFileName
    }

    if ($BackupPath) {
        $script:BackupPath = $BackupPath
    }

    if ($ConfigPath) {
        $script:ConfigPath = $ConfigPath
    }

    # Validate parameter combinations
    if ($ShowDetails -and $Mode -notin @('Assess', 'ApplyInteractive')) {
        Write-Warning "The -ShowDetails parameter only applies to Assess and ApplyInteractive modes. It will be ignored for $Mode mode."
    }

    $ProgressPreference = 'SilentlyContinue'

    # Ensure required directories exist
    @($script:BackupPath, $script:ConfigPath, (Split-Path $script:LogPath -Parent)) | ForEach-Object {
        if ($_ -and -not (Test-Path $_)) {
            New-Item -Path $_ -ItemType Directory -Force | Out-Null
        }
    }

    try {
        # Initialize log
        Initialize-Log

        # Display header
        Show-Header

        # Initialize components
        Initialize-PlatformDetection
        Initialize-HardwareDetection
        Initialize-RuntimeDetection

        # Display platform info
        Show-PlatformInfo

        # Execute based on mode
        switch ($Mode) {
            'Assess' {
                $results = Invoke-MitigationAssessment
                Show-AssessmentSummary -Results $results

                if ($ShowDetails) {
                    Show-MitigationTable -Results $results -Format 'Detailed'
                    Show-MitigationTable -Results $results -Format 'Bullets'
                }
                else {
                    Show-MitigationTable -Results $results -Format 'Simple'
                }

                Show-Recommendations -Results $results

                if ($ExportPath) {
                    Export-SideChannelAssessment -Results $results -Path $ExportPath
                }
            }

            'ApplyInteractive' {
                $results = Invoke-MitigationAssessment
                Invoke-InteractiveApply -Results $results

                if ($ExportPath) {
                    Export-SideChannelAssessment -Results $results -Path $ExportPath
                }
            }

            'Revert' {
                $backup = Get-LatestBackup
                if ($null -eq $backup) {
                    Write-Host "
$(Get-StatusIcon -Name Error) No backup found. Cannot revert." -ForegroundColor Red
                    Write-Host "Tip: Use -Mode RestoreInteractive to select from available backups." -ForegroundColor Gray
                    return
                }

                Write-Host "
=== Revert to Most Recent Backup ===" -ForegroundColor Cyan
                Write-Host "
Found most recent backup:" -ForegroundColor Yellow
                Write-Host "Timestamp: $($backup.Timestamp)" -ForegroundColor Gray
                Write-Host "Computer:  $($backup.Computer)" -ForegroundColor Gray
                Write-Host "User:      $($backup.User)" -ForegroundColor Gray
                Write-Host "
Do you want to restore this backup? (Y/N): " -NoNewline -ForegroundColor Yellow
                $confirm = Read-Host

                if ($confirm -eq 'Y') {
                    Restore-Configuration -Backup $backup
                    Write-Host "
$(Get-StatusIcon -Name Success) Configuration restored." -ForegroundColor Green
                    Write-Host "$(Get-StatusIcon -Name Warning) A system restart is required." -ForegroundColor Yellow
                }
                else {
                    Write-Host "Revert cancelled." -ForegroundColor Yellow
                }
            }

            'Backup' {
                Write-Host "
=== Create Configuration Backup ===" -ForegroundColor Cyan

                if ($WhatIfPreference) {
                    Write-Host "
[WhatIf Mode] Would create backup of current mitigation settings..." -ForegroundColor Yellow
                    $mitigations = Get-SideChannelMitigationDefinition
                    $applicableMitigations = @($mitigations | Where-Object { $_.RegistryPath -and $_.RegistryName })

                    Write-Host "
Backup would include:" -ForegroundColor Cyan
                    Write-Host "Computer:    $env:COMPUTERNAME" -ForegroundColor White
                    Write-Host "User:        $env:USERNAME" -ForegroundColor White
                    Write-Host "Mitigations: $($applicableMitigations.Count)" -ForegroundColor White
                    Write-Host "
Would save to: $script:BackupPath\Backup_<timestamp>.json" -ForegroundColor Gray
                    return
                }

                Write-Host "
Creating backup of current mitigation settings..." -ForegroundColor Yellow

                $mitigations = Get-SideChannelMitigationDefinition
                $backupFile = New-SideChannelBackup -Mitigations $mitigations

                Write-Host "
$(Get-StatusIcon -Name Success) Backup created successfully!" -ForegroundColor Green
                Write-Host "Location: $backupFile" -ForegroundColor Gray

                $backupData = Get-Content -Path $backupFile -Raw | ConvertFrom-Json
                Write-Host "
Backup Details:" -ForegroundColor Cyan
                Write-Host "Timestamp:   $($backupData.Timestamp)" -ForegroundColor White
                Write-Host "Computer:    $($backupData.Computer)" -ForegroundColor White
                Write-Host "User:        $($backupData.User)" -ForegroundColor White
                Write-Host "Mitigations: $($backupData.Mitigations.Count)" -ForegroundColor White
            }

            'RestoreInteractive' {
                $backups = @(Get-AllBackups)
                if ($backups.Count -eq 0) {
                    Write-Host "
$(Get-StatusIcon -Name Error) No backups found." -ForegroundColor Red
                    Write-Host "Create a backup first using: Invoke-SideChannelAssessment -Mode Backup" -ForegroundColor Gray
                    return
                }

                Write-Host "
=== Restore from Backup ===" -ForegroundColor Cyan
                Write-Host "Found $($backups.Count) backup(s):
" -ForegroundColor Yellow

                for ($i = 0; $i -lt $backups.Count; $i++) {
                    $bk = $backups[$i]

                    try {
                        if ($bk.Timestamp -is [DateTime]) {
                            $timestamp = $bk.Timestamp
                        }
                        else {
                            $timestamp = [DateTime]::Parse($bk.Timestamp, [System.Globalization.CultureInfo]::InvariantCulture)
                        }
                    }
                    catch {
                        try { $timestamp = [DateTime]$bk.Timestamp }
                        catch {
                            $timestamp = (Get-Item $bk.File).LastWriteTime
                        }
                    }

                    $age = (Get-Date) - $timestamp
                    $ageStr = if ($age.Days -gt 0) { "$($age.Days)d ago" }
                    elseif ($age.Hours -gt 0) { "$($age.Hours)h ago" }
                    else { "$($age.Minutes)m ago" }

                    Write-Host "[$($i+1)] " -NoNewline -ForegroundColor White
                    Write-Host "$($timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan -NoNewline
                    Write-Host " ($ageStr)" -ForegroundColor DarkGray
                    Write-Host "    Computer: $($bk.Computer) | User: $($bk.User) | Mitigations: $($bk.MitigationCount)" -ForegroundColor Gray
                }

                Write-Host "
Select backup to restore (1-$($backups.Count)) or 'Q' to quit: " -NoNewline -ForegroundColor Yellow
                $selection = Read-Host

                if ($selection -eq 'Q' -or $selection -eq 'q') {
                    Write-Host "Restore cancelled." -ForegroundColor Yellow
                    return
                }

                $selectedIndex = 0
                if (-not [int]::TryParse($selection, [ref]$selectedIndex) -or $selectedIndex -lt 1 -or $selectedIndex -gt $backups.Count) {
                    Write-Host "Invalid selection. Restore cancelled." -ForegroundColor Red
                    return
                }

                $selectedBackup = $backups[$selectedIndex - 1]
                Invoke-InteractiveRestore -Backup $selectedBackup.Data
            }
        }
    }
    catch {
        Write-Log -Message "Fatal error: $($_.Exception.Message)" -Level Error
        throw
    }
}