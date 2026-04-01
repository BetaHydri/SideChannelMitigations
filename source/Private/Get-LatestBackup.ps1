function Get-LatestBackup {
    <#
    .SYNOPSIS
        Retrieves the most recent mitigation backup.

    .DESCRIPTION
        Finds and returns the most recently created backup file from the backup directory.

    .EXAMPLE
        Get-LatestBackup

        Returns the latest backup data.
    #>
    $backupFiles = @(Get-ChildItem -Path $script:BackupPath -Filter "Backup_*.json" -ErrorAction SilentlyContinue)

    if ($backupFiles.Count -eq 0) {
        return $null
    }

    $latest = $backupFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return Get-Content -Path $latest.FullName -Raw | ConvertFrom-Json
}