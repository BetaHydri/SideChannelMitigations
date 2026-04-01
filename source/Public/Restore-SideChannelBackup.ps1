function Restore-SideChannelBackup
{
    <#
    .SYNOPSIS
        Restore side-channel mitigation settings from a backup file.

    .DESCRIPTION
        Restores previously backed-up side-channel mitigation registry settings.
        Can restore from a specific backup file or the latest available backup.

    .PARAMETER Path
        Path to a specific backup JSON file to restore from.

    .PARAMETER Latest
        Restore from the most recent backup file.

    .PARAMETER BackupPath
        Directory containing backup files. Defaults to the module backup directory.

    .EXAMPLE
        Restore-SideChannelBackup -Latest

        Restore from the most recent backup.

    .EXAMPLE
        Restore-SideChannelBackup -Path '.\Backups\Backup_20260101_120000.json'

        Restore from a specific backup file.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Latest')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Latest')]
    param(
        [Parameter(ParameterSetName = 'ByPath', Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path,

        [Parameter(ParameterSetName = 'Latest')]
        [switch]$Latest,

        [Parameter()]
        [string]$BackupPath
    )

    if ($BackupPath) {
        $script:BackupPath = $BackupPath
    }

    if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
        $backupData = Get-Content -Path $Path -Raw | ConvertFrom-Json
    }
    else {
        $backupData = Get-LatestBackup

        if ($null -eq $backupData) {
            Write-Error 'No backup found. Create a backup first using New-SideChannelBackup.'
            return
        }
    }

    if ($PSCmdlet.ShouldProcess("Mitigation settings from backup $($backupData.Timestamp)", 'Restore')) {
        Restore-Configuration -Backup $backupData
    }
}