function Show-AssessmentSummary {
    <#
    .SYNOPSIS
        Displays the assessment summary with statistics.

    .DESCRIPTION
        Shows a formatted console summary of protected, vulnerable, and unknown mitigation counts with visual progress bar.

    .PARAMETER Results
        The array of mitigation assessment result objects to process.

    .EXAMPLE
        Show-AssessmentSummary -Results $assessmentResults

        Displays the assessment summary table.
    #>
    param([array]$Results)

    Write-Host "`n--- Security Assessment Summary ---" -ForegroundColor Yellow

    # Separate prerequisites from actual mitigations
    $prerequisites = @($Results | Where-Object { $_.Category -eq 'Prerequisite' })
    $mitigations = @($Results | Where-Object { $_.Category -ne 'Prerequisite' })

    # Calculate for mitigations only (exclude N/A)
    $applicableMitigations = @($mitigations | Where-Object { $_.OverallStatus -ne 'Not Applicable' })
    $protected = @($applicableMitigations | Where-Object { $_.OverallStatus -eq 'Protected' }).Count
    $vulnerable = @($applicableMitigations | Where-Object { $_.OverallStatus -eq 'Vulnerable' }).Count
    $unknown = @($applicableMitigations | Where-Object { $_.OverallStatus -eq 'Unknown' }).Count
    $notApplicable = @($mitigations | Where-Object { $_.OverallStatus -eq 'Not Applicable' }).Count
    $total = $applicableMitigations.Count

    $protectionPercent = if ($total -gt 0) { [math]::Round(($protected / $total) * 100, 1) } else { 0 }

    Write-Host "Total Mitigations Evaluated:  " -NoNewline
    Write-Host $total -ForegroundColor White

    Write-Host "Protected:                    " -NoNewline
    Write-Host "$protected " -ForegroundColor Green -NoNewline
    Write-Host "($protectionPercent%)"

    if ($vulnerable -gt 0) {
        Write-Host "Vulnerable:                   " -NoNewline
        Write-Host $vulnerable -ForegroundColor Red
    }

    if ($unknown -gt 0) {
        Write-Host "Unknown Status:               " -NoNewline
        Write-Host $unknown -ForegroundColor Gray
    }

    # Visual progress bar with block characters
    Write-Host "`nSecurity Score: " -NoNewline
    $barLength = 40
    $filledLength = [math]::Round(($protectionPercent / 100) * $barLength)
    $emptyLength = $barLength - $filledLength

    # Determine color based on percentage
    $barColor = if ($protectionPercent -ge 90) { 'Green' }
    elseif ($protectionPercent -ge 75) { 'Cyan' }
    elseif ($protectionPercent -ge 50) { 'Yellow' }
    else { 'Red' }

    # Get block characters
    $blockFull = Get-StatusIcon -Name BlockFull
    $blockLight = Get-StatusIcon -Name BlockLight

    # Build progress bar using filled/empty blocks
    Write-Host "[" -NoNewline
    if ($filledLength -gt 0) {
        Write-Host ($blockFull * $filledLength) -ForegroundColor $barColor -NoNewline
    }
    if ($emptyLength -gt 0) {
        Write-Host ($blockLight * $emptyLength) -ForegroundColor DarkGray -NoNewline
    }
    Write-Host "] " -NoNewline
    Write-Host "$protectionPercent%" -ForegroundColor $barColor

    # Security level
    Write-Host "Security Level: " -NoNewline
    if ($protectionPercent -ge 90) {
        Write-Host "Excellent" -ForegroundColor Green
    }
    elseif ($protectionPercent -ge 75) {
        Write-Host "Good" -ForegroundColor Cyan
    }
    elseif ($protectionPercent -ge 50) {
        Write-Host "Fair" -ForegroundColor Yellow
    }
    else {
        Write-Host "Poor - Action Required" -ForegroundColor Red
    }

    # Show hardware prerequisites status
    if ($prerequisites.Count -gt 0) {
        Write-Host "`n--- Hardware Prerequisites ---" -ForegroundColor Yellow
        $prereqEnabled = @($prerequisites | Where-Object { $_.OverallStatus -in @('Protected', 'Active') }).Count
        $prereqMissing = @($prerequisites | Where-Object { $_.OverallStatus -eq 'Missing' }).Count
        $prereqVulnerable = @($prerequisites | Where-Object { $_.OverallStatus -eq 'Vulnerable' }).Count

        Write-Host "Prerequisites Enabled: " -NoNewline
        Write-Host "$prereqEnabled" -ForegroundColor Green -NoNewline
        Write-Host " / $($prerequisites.Count)"

        if ($prereqVulnerable -gt 0) {
            Write-Host "Capable but Disabled:  " -NoNewline
            Write-Host "$prereqVulnerable" -ForegroundColor Yellow
        }

        if ($prereqMissing -gt 0) {
            Write-Host "Not Available:         " -NoNewline
            Write-Host "$prereqMissing" -ForegroundColor Red
        }
    }

    if ($notApplicable -gt 0) {
        Write-Host "`nNote: $notApplicable mitigation(s) not applicable (hardware requirements not met)" -ForegroundColor Gray
    }
}