function Invoke-InteractiveApply {
    <#
    .SYNOPSIS
        Provides interactive menu for applying mitigations.

    .DESCRIPTION
        Displays an interactive console menu allowing the user to select and apply individual mitigations with confirmation prompts.

    .PARAMETER Results
        The array of mitigation assessment result objects to process.

    .EXAMPLE
        Invoke-InteractiveApply -Results $assessmentResults

        Shows interactive apply menu with assessment results.
    #>
    param([array]$Results)

    Write-Host "`n=== Interactive Mitigation Application ===" -ForegroundColor Cyan
    if ($WhatIfPreference) {
        Write-Host "[WhatIf Mode] Changes will be previewed but not applied`n" -ForegroundColor Yellow
    }

    # Ask if user wants to see only actionable items or all mitigations
    Write-Host "Selection mode:" -ForegroundColor Yellow
    Write-Host "  [R] Show only recommended/actionable mitigations" -ForegroundColor White
    Write-Host "  [A] Show all available mitigations (for selective hardening)" -ForegroundColor White
    Write-Host "`nYour choice (R/A) [Default: R]: " -NoNewline -ForegroundColor Yellow
    $viewMode = Read-Host

    if ([string]::IsNullOrWhiteSpace($viewMode)) {
        $viewMode = 'R'
    }

    $itemsToShow = @()

    if ($viewMode -eq 'A' -or $viewMode -eq 'a') {
        # Show ALL mitigations, allowing user to enable anything
        $itemsToShow = @($Results)
        Write-Host "`nShowing all $($itemsToShow.Count) available mitigations:`n" -ForegroundColor Cyan
    }
    else {
        # Show only actionable items (original behavior)
        $itemsToShow = @($Results | Where-Object { $_.ActionNeeded -match 'Yes|Consider' })

        if ($itemsToShow.Count -eq 0) {
            Write-Host "`nNo mitigations require configuration!" -ForegroundColor Green
            Write-Host "Tip: Use selection mode [A] to see all available mitigations." -ForegroundColor Gray
            return
        }

        Write-Host "`nShowing $($itemsToShow.Count) recommended/actionable mitigations:`n" -ForegroundColor Cyan
    }

    # Display options
    for ($i = 0; $i -lt $itemsToShow.Count; $i++) {
        $item = $itemsToShow[$i]

        # Determine color based on current status and action needed
        $statusColor = if ($item.OverallStatus -eq 'Protected') {
            'Green'
        }
        else {
            switch -Wildcard ($item.ActionNeeded) {
                '*Critical*' { 'Red' }
                '*Recommended*' { 'Yellow' }
                default { 'Cyan' }
            }
        }

        $statusIndicator = if ($item.OverallStatus -eq 'Protected') { "$(Get-StatusIcon -Name Success) " } else { "" }

        Write-Host "[$($i+1)] " -NoNewline
        Write-Host "$statusIndicator$($item.Name)" -ForegroundColor $statusColor
        Write-Host "    Status: $($item.OverallStatus) | Impact: $($item.Impact)" -ForegroundColor Gray
        if ($item.Recommendation) {
            Write-Host "    $($item.Recommendation)" -ForegroundColor DarkGray
        }
    }

    $bullet = Get-StatusIcon -Name Bullet
    Write-Host "`nSelection options:" -ForegroundColor Cyan
    Write-Host "  $bullet Enter numbers (e.g., '1,2,5' or '2-4,6-8')" -ForegroundColor White
    Write-Host "  $bullet Type 'all' to select all shown mitigations" -ForegroundColor White
    Write-Host "  $bullet Type 'critical' to select only critical items" -ForegroundColor White
    Write-Host "  $bullet Type 'Q' to quit" -ForegroundColor White
    Write-Host "`nYour selection: " -NoNewline -ForegroundColor Yellow
    $selection = Read-Host

    if ($selection -eq 'Q' -or $selection -eq 'q') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    # Parse selection
    $selectedItems = @()

    if ($selection -eq 'all') {
        $selectedItems = $itemsToShow
    }
    elseif ($selection -eq 'critical') {
        $selectedItems = @($itemsToShow | Where-Object { $_.ActionNeeded -match 'Critical' })
        if ($selectedItems.Count -eq 0) {
            Write-Host "No critical items found in current view." -ForegroundColor Yellow
            return
        }
    }
    else {
        # Parse numbers
        $indices = @()
        foreach ($part in ($selection -split ',')) {
            if ($part -match '(\d+)-(\d+)') {
                $start = [int]$Matches[1]
                $end = [int]$Matches[2]
                $indices += $start..$end
            }
            elseif ($part -match '^\d+$') {
                $indices += [int]$part
            }
        }

        $selectedItems = @($indices | ForEach-Object {
                if ($_ -ge 1 -and $_ -le $itemsToShow.Count) {
                    $itemsToShow[$_ - 1]
                }
            })
    }

    if ($selectedItems.Count -eq 0) {
        Write-Host "No items selected. Exiting." -ForegroundColor Yellow
        return
    }

    # Confirm
    Write-Host "`nYou have selected $($selectedItems.Count) mitigation(s):" -ForegroundColor Cyan
    $selectedItems | ForEach-Object { Write-Host "  $(Get-StatusIcon -Name Bullet) $($_.Name)" -ForegroundColor White }

    if ($WhatIfPreference) {
        Write-Host "`n=== WhatIf: Changes Preview ===" -ForegroundColor Cyan
        Write-Host "The following changes would be made:`n" -ForegroundColor Yellow

        $mitigations = Get-SideChannelMitigationDefinition
        foreach ($item in $selectedItems) {
            $mitigation = $mitigations | Where-Object { $_.Id -eq $item.Id }
            if ($mitigation) {
                Write-Host "[$($mitigation.Id)] $($mitigation.Name)" -ForegroundColor White
                Write-Host "  Registry Path: $($mitigation.RegistryPath)" -ForegroundColor Gray
                Write-Host "  Registry Name: $($mitigation.RegistryName)" -ForegroundColor Gray
                Write-Host "  New Value: $($mitigation.EnabledValue)" -ForegroundColor Green
                Write-Host "  Impact: $($mitigation.Impact)`n" -ForegroundColor Gray
            }
        }

        Write-Host "WhatIf Summary:" -ForegroundColor Cyan
        Write-Host "Total changes that would be made: $($selectedItems.Count)" -ForegroundColor White
        Write-Host "Backup would be created: Yes (selected mitigations only)" -ForegroundColor White
        Write-Host "System restart would be required: Yes" -ForegroundColor Yellow
        return
    }

    Write-Host "`nA selective backup of the chosen mitigations will be created before applying changes."
    Write-Host "Tip: Use '-Mode Backup' for a full backup of all mitigations." -ForegroundColor Gray
    Write-Host "Do you want to proceed? (Y/N): " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host

    if ($confirm -ne 'Y') {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        return
    }

    # Create backup of only the selected mitigations (not all)
    # For a full backup of all mitigations, use: Invoke-SideChannelAssessment -Mode Backup
    $mitigations = Get-SideChannelMitigationDefinition
    $selectedMitigations = @($mitigations | Where-Object { $_.Id -in $selectedItems.Id })
    $backupFile = New-SideChannelBackup -Mitigations $selectedMitigations
    Write-Log "Selective backup created with $($selectedMitigations.Count) mitigation(s)" -Level Info

    # Apply
    Write-Host "`nApplying mitigations..." -ForegroundColor Cyan

    $success = 0
    $failed = 0
    $skipped = 0

    foreach ($item in $selectedItems) {
        $mitigation = $mitigations | Where-Object { $_.Id -eq $item.Id }
        if ($mitigation) {
            $result = Set-MitigationValue -Mitigation $mitigation
            if ($result -eq $true) {
                $success++
            }
            elseif ($result -eq $false) {
                $failed++
            }
            else {
                # $null means skipped (hardware-only)
                $skipped++
            }
        }
    }

    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Successfully applied: $success" -ForegroundColor Green
    if ($failed -gt 0) {
        Write-Host "Failed: $failed" -ForegroundColor Red
    }
    if ($skipped -gt 0) {
        Write-Host "Skipped (hardware-only): $skipped" -ForegroundColor Gray
    }
    Write-Host "Backup saved: $backupFile" -ForegroundColor Gray

    Write-Host "`n$(Get-StatusIcon -Name Warning) A system restart is required for changes to take effect." -ForegroundColor Yellow
}