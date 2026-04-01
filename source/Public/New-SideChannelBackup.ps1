function New-SideChannelBackup {
    <#
    .SYNOPSIS
        Creates a backup of current mitigation registry settings.

    .DESCRIPTION
        Reads current registry values for all defined mitigations and saves them as a timestamped JSON backup file.

    .PARAMETER Mitigations
        Array of mitigation definition hashtables to back up registry values for.

    .EXAMPLE
        New-SideChannelBackup -Mitigations (Get-SideChannelMitigationDefinition)

        Creates a backup of the current mitigation configuration.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([array]$Mitigations)

    Write-Log "Creating configuration backup..." -Level Info

    $backupFile = Join-Path $script:BackupPath "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

    $backupData = @{
        Timestamp   = Get-Date -Format 'o'
        Computer    = $env:COMPUTERNAME
        User        = $env:USERNAME
        Mitigations = @()
    }

    foreach ($mitigation in $Mitigations) {
        try {
            $regItem = Get-ItemProperty -Path $mitigation.RegistryPath -Name $mitigation.RegistryName -ErrorAction Stop
            $value = $regItem.($mitigation.RegistryName)
        }
        catch {
            $value = $null
        }

        $backupData.Mitigations += @{
            Id           = $mitigation.Id
            Name         = $mitigation.Name
            RegistryPath = $mitigation.RegistryPath
            RegistryName = $mitigation.RegistryName
            Value        = $value
        }
    }

    $backupData | ConvertTo-Json -Depth 10 | Set-Content -Path $backupFile -Encoding UTF8
    Write-Log "Backup created: $backupFile" -Level Success
    return $backupFile
}