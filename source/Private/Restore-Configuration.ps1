function Restore-Configuration {
    <#
    .SYNOPSIS
        Restores registry settings from a backup object.

    .DESCRIPTION
        Applies previously backed-up registry values to restore mitigation configurations to a prior state.

    .PARAMETER Backup
        The backup data object containing previously saved registry values to restore.

    .EXAMPLE
        Restore-Configuration -BackupData $backupObject

        Restores mitigations from a backup.
    #>
    param([object]$Backup)

    if ($WhatIfPreference) {
        Write-Host "`n=== WhatIf: Configuration Restore Preview ===" -ForegroundColor Cyan
        Write-Host "Would restore configuration from: $($Backup.Timestamp)" -ForegroundColor Yellow
        Write-Host "`nChanges that would be made:" -ForegroundColor White

        foreach ($item in $Backup.Mitigations) {
            if ($null -eq $item.Value) {
                Write-Host "  [-] Would remove: $($item.RegistryPath)\$($item.RegistryName)" -ForegroundColor Red
            }
            else {
                Write-Host "  [+] Would set: $($item.RegistryPath)\$($item.RegistryName) = $($item.Value)" -ForegroundColor Green
            }
        }

        Write-Host "`nTotal changes that would be made: $($Backup.Mitigations.Count)" -ForegroundColor Cyan
        Write-Host "System restart would be required: Yes" -ForegroundColor Yellow
        return
    }

    Write-Log "Restoring configuration from $($Backup.Timestamp)" -Level Info

    $success = 0
    $failed = 0
    $skipped = 0

    # Filter out hardware-only items (no registry path)
    $restorableItems = @($Backup.Mitigations | Where-Object { -not [string]::IsNullOrEmpty($_.RegistryPath) })

    foreach ($item in $restorableItems) {
        try {
            if ($null -eq $item.Value) {
                Remove-ItemProperty -Path $item.RegistryPath -Name $item.RegistryName -ErrorAction SilentlyContinue
                Write-Log "Removed: $($item.Name)" -Level Info
            }
            else {
                Set-ItemProperty -Path $item.RegistryPath -Name $item.RegistryName -Value $item.Value -Force
                Write-Log "Restored: $($item.Name)" -Level Info
            }
            $success++
        }
        catch {
            Write-Log "Could not restore $($item.Name): $($_.Exception.Message)" -Level Warning
            $failed++
        }
    }

    # Count skipped hardware items
    $skipped = $Backup.Mitigations.Count - $restorableItems.Count

    Write-Host "`n=== Restore Summary ===" -ForegroundColor Cyan
    Write-Host "Successfully restored: $success" -ForegroundColor Green
    if ($failed -gt 0) {
        Write-Host "Failed: $failed" -ForegroundColor Red
    }
    if ($skipped -gt 0) {
        Write-Host "Skipped (hardware-only): $skipped" -ForegroundColor Gray
    }

    Write-Log "Configuration restored: $success successful, $failed failed, $skipped skipped" -Level Success
}