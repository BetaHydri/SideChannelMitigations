function Invoke-InteractiveRestore {
    <#
    .SYNOPSIS
        Provides interactive menu for restoring backup configurations.

    .DESCRIPTION
        Displays available backups and allows the user to select one for restoration with confirmation prompts.

    .PARAMETER Backup
        The backup data object containing previously saved registry values to restore.

    .EXAMPLE
        Invoke-InteractiveRestore -Results $assessmentResults

        Shows interactive restore menu.
    #>
    param([object]$Backup)

    Write-Host "`n=== Interactive Restore ===" -ForegroundColor Cyan
    if ($WhatIfPreference) {
        Write-Host "[WhatIf Mode] Changes will be previewed but not applied`n" -ForegroundColor Yellow
    }
    Write-Host "Select mitigations to restore (or 'all' for all settings)`n"

    # Filter to only restorable items (exclude hardware-only)
    $restorableItems = @($Backup.Mitigations | Where-Object { -not [string]::IsNullOrEmpty($_.RegistryPath) })

    if ($restorableItems.Count -eq 0) {
        Write-Host "No restorable mitigations found in backup (hardware-only items)." -ForegroundColor Yellow
        return
    }

    # Display restorable mitigations from backup
    for ($i = 0; $i -lt $restorableItems.Count; $i++) {
        $item = $restorableItems[$i]
        $valueDisplay = if ($null -eq $item.Value) { "[DELETE]" } else { $item.Value }

        Write-Host "[$($i+1)] " -NoNewline -ForegroundColor Cyan
        Write-Host "$($item.Name)" -ForegroundColor White -NoNewline
        Write-Host " = $valueDisplay" -ForegroundColor Gray
    }

    Write-Host "`nEnter numbers (e.g., '1,3,5' or '2-4,6-8'), 'all', or 'Q' to quit: " -NoNewline -ForegroundColor Yellow
    $selection = Read-Host

    if ($selection -eq 'Q' -or $selection -eq 'q') {
        Write-Host "Restore cancelled." -ForegroundColor Yellow
        return
    }

    $selectedItems = @()

    if ($selection -eq 'all' -or $selection -eq 'All') {
        $selectedItems = $restorableItems
    }
    else {
        # Parse selection supporting ranges (e.g., "2-4") and individual numbers (e.g., "1,5")
        $parts = $selection -split ',' | ForEach-Object { $_.Trim() }
        $expandedNumbers = @()

        foreach ($part in $parts) {
            if ($part -match '^(\d+)-(\d+)$') {
                # Range notation (e.g., "2-4")
                $start = [int]$matches[1]
                $end = [int]$matches[2]
                if ($start -le $end) {
                    $expandedNumbers += $start..$end
                }
                else {
                    # Support reverse ranges (e.g., "4-2" becomes 4,3,2)
                    $expandedNumbers += $start..$end
                }
            }
            elseif ($part -match '^\d+$') {
                # Single number
                $expandedNumbers += [int]$part
            }
        }

        # Remove duplicates and get items
        $uniqueNumbers = $expandedNumbers | Select-Object -Unique
        $tempItems = foreach ($num in $uniqueNumbers) {
            if ($num -ge 1 -and $num -le $restorableItems.Count) {
                $restorableItems[$num - 1]
            }
        }
        $selectedItems = @($tempItems)
    }

    if ($selectedItems.Count -eq 0) {
        Write-Host "No valid selections made. Restore cancelled." -ForegroundColor Red
        return
    }

    # Show what will be restored
    Write-Host "`nSelected mitigations to restore:" -ForegroundColor Cyan
    foreach ($item in $selectedItems) {
        $valueDisplay = if ($null -eq $item.Value) { "[DELETE]" } else { $item.Value }
        Write-Host "  $(Get-StatusIcon -Name Bullet) $($item.Name) = $valueDisplay" -ForegroundColor White
    }

    Write-Host "`nRestore these $($selectedItems.Count) mitigation(s)? (Y/N): " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host

    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Host "Restore cancelled." -ForegroundColor Yellow
        return
    }

    # Perform the restore
    if ($WhatIfPreference) {
        Write-Host "`n=== WhatIf: Would restore these settings ===" -ForegroundColor Cyan
        foreach ($item in $selectedItems) {
            if ($null -eq $item.Value) {
                Write-Host "  [-] Would remove: $($item.RegistryPath)\$($item.RegistryName)" -ForegroundColor Red
            }
            else {
                Write-Host "  [+] Would set: $($item.RegistryPath)\$($item.RegistryName) = $($item.Value)" -ForegroundColor Green
            }
        }
        Write-Host "`nTotal changes that would be made: $($selectedItems.Count)" -ForegroundColor Cyan
        Write-Host "System restart would be required: Yes" -ForegroundColor Yellow
        return
    }

    Write-Log "Restoring $($selectedItems.Count) selected mitigation(s) from $($Backup.Timestamp)" -Level Info

    $success = 0
    $failed = 0

    foreach ($item in $selectedItems) {
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

    Write-Host "`n=== Restore Summary ===" -ForegroundColor Cyan
    Write-Host "Successfully restored: $success" -ForegroundColor Green
    if ($failed -gt 0) {
        Write-Host "Failed: $failed" -ForegroundColor Red
    }

    Write-Host "`n$(Get-StatusIcon -Name Success) Selected mitigations restored from backup." -ForegroundColor Green
    Write-Host "$(Get-StatusIcon -Name Warning) A system restart is required." -ForegroundColor Yellow

    Write-Log "Interactive restore complete: $success successful, $failed failed" -Level Success
}