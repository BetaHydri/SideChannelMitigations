function Set-MitigationValue {
    <#
    .SYNOPSIS
        Sets a registry value for a mitigation configuration.

    .DESCRIPTION
        Creates or updates a registry value at the specified path to configure a side-channel mitigation.

    .PARAMETER Mitigation
        The mitigation definition hashtable containing RegistryPath, RegistryName, and EnabledValue.

    .EXAMPLE
        Set-MitigationValue -Mitigation $mitigationDef

        Sets a registry value for the specified mitigation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [hashtable]$Mitigation
    )

    # Check if this is a hardware-only prerequisite (no registry path)
    if ([string]::IsNullOrEmpty($Mitigation.RegistryPath) -or [string]::IsNullOrEmpty($Mitigation.RegistryName)) {
        Write-Log "Skipped: $($Mitigation.Name) (hardware-only, configure in BIOS/UEFI)" -Level Info
        Write-Host "  [Info] Skipped: $($Mitigation.Name) - Configure in BIOS/UEFI firmware" -ForegroundColor Gray
        return $null  # Return null to indicate skip (not success/failure)
    }

    if ($WhatIfPreference) {
        Write-Log "[WhatIf] Would apply: $($Mitigation.Name)" -Level Info
        Write-Host "  [WhatIf] Would set: $($Mitigation.RegistryPath)\$($Mitigation.RegistryName) = $($Mitigation.EnabledValue)" -ForegroundColor Cyan
        return $true
    }

    Write-Log "Applying: $($Mitigation.Name)" -Level Info

    try {
        # Ensure registry path exists
        if (-not (Test-Path $Mitigation.RegistryPath)) {
            New-Item -Path $Mitigation.RegistryPath -Force | Out-Null
        }

        # Determine value type
        $valueType = 'DWord'
        if ($Mitigation.EnabledValue -is [uint64] -or $Mitigation.EnabledValue -gt 0xFFFFFFFF) {
            $valueType = 'QWord'
        }

        Set-ItemProperty -Path $Mitigation.RegistryPath `
            -Name $Mitigation.RegistryName `
            -Value $Mitigation.EnabledValue `
            -Type $valueType -Force

        Write-Log "Applied: $($Mitigation.Name)" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to apply $($Mitigation.Name): $($_.Exception.Message)" -Level Error
        return $false
    }
}