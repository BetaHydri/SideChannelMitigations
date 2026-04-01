function Get-AllBackups {
    <#
    .SYNOPSIS
        Retrieves all available mitigation backup files.

    .DESCRIPTION
        Scans the backup directory for JSON backup files and returns parsed backup objects sorted by date.

    .EXAMPLE
        Get-AllBackups

        Lists all available backup files.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    param()

    $backupFiles = @(Get-ChildItem -Path $script:BackupPath -Filter "Backup_*.json" -ErrorAction SilentlyContinue)

    if ($backupFiles.Count -eq 0) {
        return @()
    }

    $backups = @()
    foreach ($file in ($backupFiles | Sort-Object LastWriteTime -Descending)) {
        try {
            $backup = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $backups += [PSCustomObject]@{
                File            = $file.FullName
                FileName        = $file.Name
                Timestamp       = $backup.Timestamp
                Computer        = $backup.Computer
                User            = $backup.User
                MitigationCount = $backup.Mitigations.Count
                FileSize        = $file.Length
                Data            = $backup
            }
        }
        catch {
            Write-Log "Could not parse backup file $($file.Name): $($_.Exception.Message)" -Level Warning
        }
    }

    return $backups
}