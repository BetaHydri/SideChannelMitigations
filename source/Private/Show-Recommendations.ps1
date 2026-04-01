function Show-Recommendations {
    <#
    .SYNOPSIS
        Displays security recommendations based on assessment results.

    .DESCRIPTION
        Analyzes assessment results and shows prioritized recommendations for improving side-channel vulnerability protection.

    .PARAMETER Results
        The array of assessment result objects to analyze for actionable recommendations.

    .EXAMPLE
        Show-Recommendations -Results $assessmentResults

        Displays security recommendations.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    param([array]$Results)

    $actionable = @($Results | Where-Object { $_.ActionNeeded -match 'Yes|Consider' })

    if ($actionable.Count -eq 0) {
        Write-Host "`n$(Get-StatusIcon -Name Success) All critical mitigations are properly configured!" -ForegroundColor Green
        return
    }

    Write-Host "`n--- Recommendations ---" -ForegroundColor Yellow

    $critical = @($actionable | Where-Object { $_.ActionNeeded -match 'Critical' })
    $recommended = @($actionable | Where-Object { $_.ActionNeeded -match 'Recommended' })
    $optional = @($actionable | Where-Object { $_.ActionNeeded -eq 'Consider' })

    if ($critical.Count -gt 0) {
        Write-Host "`n$(Get-StatusIcon -Name RedCircle) CRITICAL - Apply immediately:" -ForegroundColor Red
        foreach ($item in $critical) {
            Write-Host "   $(Get-StatusIcon -Name Bullet) $($item.Name)" -ForegroundColor White

            # Provide context-aware recommendation based on status
            if ($item.RuntimeStatus -match 'Microcode Update Required') {
                Write-Host "     $(Get-StatusIcon -Name Warning) Registry configured but CPU microcode missing" -ForegroundColor Yellow
                Write-Host "     Action: Update BIOS/UEFI firmware to get latest CPU microcode" -ForegroundColor Gray
            }
            elseif ($item.RegistryStatus -eq 'Not Configured') {
                Write-Host "     Action: Enable this mitigation (registry not configured)" -ForegroundColor Gray
                Write-Host "     $($item.Recommendation)" -ForegroundColor DarkGray
            }
            else {
                Write-Host "     $($item.Recommendation)" -ForegroundColor Gray
            }

            if ($item.Impact -eq 'High') {
                Write-Host "     $(Get-StatusIcon -Name Warning) Performance Impact: HIGH" -ForegroundColor Yellow
            }
        }
    }

    if ($recommended.Count -gt 0) {
        Write-Host "`n$(Get-StatusIcon -Name YellowCircle) RECOMMENDED - Apply for enhanced security:" -ForegroundColor Yellow
        foreach ($item in $recommended) {
            Write-Host "   $(Get-StatusIcon -Name Bullet) $($item.Name)" -ForegroundColor White

            # Provide context-aware recommendation based on status
            if ($item.RuntimeStatus -match 'Microcode Update Required') {
                Write-Host "     $(Get-StatusIcon -Name Warning) Registry configured but CPU microcode missing" -ForegroundColor Yellow
                Write-Host "     Action: Update BIOS/UEFI firmware to get latest CPU microcode" -ForegroundColor Gray
            }
            elseif ($item.RegistryStatus -eq 'Not Configured') {
                Write-Host "     $($item.Recommendation)" -ForegroundColor Gray
            }
            else {
                Write-Host "     $($item.Recommendation)" -ForegroundColor Gray
            }
        }
    }

    if ($optional.Count -gt 0) {
        Write-Host "`n$(Get-StatusIcon -Name YellowCircle) OPTIONAL - Evaluate based on environment:" -ForegroundColor Yellow
        foreach ($item in $optional) {
            Write-Host "   $(Get-StatusIcon -Name Bullet) $($item.Name)" -ForegroundColor White
            Write-Host "     $($item.Recommendation)" -ForegroundColor Gray
        }
    }

    # Check if any items show "Inactive (Microcode Update Required)" status
    $microcodeRequired = @($Results | Where-Object { $_.RuntimeStatus -match 'Microcode Update Required' })
    if ($microcodeRequired.Count -gt 0) {
        Write-Host "`n$(Get-StatusIcon -Name Warning) MICROCODE UPDATE REQUIRED:" -ForegroundColor Yellow
        Write-Host "   The following mitigations have registry values set but are still inactive:" -ForegroundColor Gray
        foreach ($item in $microcodeRequired) {
            Write-Host "   $(Get-StatusIcon -Name Bullet) $($item.Name) - Registry configured but kernel mitigation inactive" -ForegroundColor Yellow
        }
        Write-Host "`n   This typically means:" -ForegroundColor Cyan
        Write-Host "   $(Get-StatusIcon -Name Bullet) CPU microcode update is missing or outdated" -ForegroundColor Gray
        Write-Host "   $(Get-StatusIcon -Name Bullet) Update BIOS/UEFI firmware to latest version" -ForegroundColor Gray
        Write-Host "   $(Get-StatusIcon -Name Bullet) Check with your hardware vendor for microcode updates" -ForegroundColor Gray
        Write-Host "   $(Get-StatusIcon -Name Bullet) Some older CPUs may not receive microcode updates" -ForegroundColor DarkGray
        if ($script:PlatformInfo.Type -eq 'VM' -or $script:PlatformInfo.Type -eq 'HyperVGuest' -or $script:PlatformInfo.Type -eq 'VMwareGuest') {
            Write-Host "`n   $(Get-StatusIcon -Name Info) VM Note: Hypervisor host must have microcode updates and mitigations enabled first" -ForegroundColor Cyan
        }
    }

    Write-Host "`nTo apply mitigations, run:" -ForegroundColor Cyan
    Write-Host "   .\SideChannel_Check_v2.ps1 -Mode ApplyInteractive" -ForegroundColor White
}