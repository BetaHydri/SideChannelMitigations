function Show-MitigationTable {
    <#
    .SYNOPSIS
        Displays the mitigation results in a formatted table.

    .DESCRIPTION
        Renders a color-coded console table showing each mitigation status with icons and formatting.

    .PARAMETER Results
        The array of mitigation assessment result objects to process.

    .PARAMETER Format
        The output format style: Detailed (default) or Compact table layout.

    .EXAMPLE
        Show-MitigationTable -Results $assessmentResults

        Displays the mitigation status table.
    #>
    param(
        [array]$Results,
        [ValidateSet('Simple', 'Detailed', 'Bullets')]
        [string]$Format = 'Simple'
    )

    Write-Host "`n--- Mitigation Status ---" -ForegroundColor Yellow

    # Check PowerShell version for ANSI support
    $useAnsi = $PSVersionTable.PSVersion.Major -ge 6

    switch ($Format) {
        'Bullets' {
            # Enhanced detailed view with educational information (bullet-point format)
            foreach ($result in $Results) {
                $statusColor = switch ($result.OverallStatus) {
                    'Protected' { 'Green' }
                    'Active' { 'Green' }
                    'Vulnerable' { 'Red' }
                    'Missing' { 'Red' }
                    'Unknown' { 'Yellow' }
                    default { 'Gray' }
                }

                Write-Host "`n$(Get-StatusIcon -Name Bullet) " -NoNewline -ForegroundColor Cyan
                Write-Host $result.Name -ForegroundColor White -NoNewline
                Write-Host " [" -NoNewline -ForegroundColor DarkGray
                Write-Host $result.OverallStatus -ForegroundColor $statusColor -NoNewline
                Write-Host "]" -ForegroundColor DarkGray

                # Show CVE if available
                if ($result.CVE -and $result.CVE -ne 'N/A') {
                    Write-Host "  CVE:          " -NoNewline -ForegroundColor Gray
                    Write-Host $result.CVE -ForegroundColor Yellow
                }

                # Show URL if available
                if ($result.PSObject.Properties.Name -contains 'URL' -and $result.URL) {
                    Write-Host "  Reference:    " -NoNewline -ForegroundColor Gray
                    Write-Host $result.URL -ForegroundColor Blue
                }

                # Show PrerequisiteFor if available (for prerequisites)
                if ($result.Category -eq 'Prerequisite') {
                    $mitigationDef = (Get-SideChannelMitigationDefinition) | Where-Object { $_.Id -eq $result.Id }
                    if ($mitigationDef -and $mitigationDef.PrerequisiteFor) {
                        Write-Host "  Required For: " -NoNewline -ForegroundColor Gray
                        Write-Host $mitigationDef.PrerequisiteFor -ForegroundColor Magenta
                    }
                }

                # Show Description if available
                if ($result.Description) {
                    Write-Host "  Description:  " -NoNewline -ForegroundColor Gray
                    Write-Host $result.Description -ForegroundColor Cyan
                }

                # Show Runtime vs Registry Status with icons and color coding
                if ($result.RuntimeStatus -and $result.RuntimeStatus -ne 'N/A') {
                    Write-Host "  Runtime:      " -NoNewline -ForegroundColor Gray

                    # Determine icon and color based on runtime status
                    if ($result.RuntimeStatus -match '^Active') {
                        # Active, Active (Enhanced IBRS), Active (Retpoline), etc.
                        Write-Host "$(Get-StatusIcon -Name Success) " -NoNewline -ForegroundColor Green
                        Write-Host $result.RuntimeStatus -ForegroundColor Green
                    }
                    elseif ($result.RuntimeStatus -eq 'Inactive') {
                        Write-Host "$(Get-StatusIcon -Name Cross) " -NoNewline -ForegroundColor Red
                        Write-Host $result.RuntimeStatus -ForegroundColor Red
                    }
                    elseif ($result.RuntimeStatus -match 'Not Needed|Immune') {
                        Write-Host "$(Get-StatusIcon -Name Info) " -NoNewline -ForegroundColor Cyan
                        Write-Host $result.RuntimeStatus -ForegroundColor Cyan
                    }
                    elseif ($result.RuntimeStatus -eq 'Supported') {
                        Write-Host "$(Get-StatusIcon -Name Info) " -NoNewline -ForegroundColor Cyan
                        Write-Host $result.RuntimeStatus -ForegroundColor Cyan
                    }
                    elseif ($result.RuntimeStatus -match 'Not Present|Not Supported') {
                        Write-Host "$(Get-StatusIcon -Name Cross) " -NoNewline -ForegroundColor Red
                        Write-Host $result.RuntimeStatus -ForegroundColor Red
                    }
                    else {
                        Write-Host "$(Get-StatusIcon -Name Info) " -NoNewline -ForegroundColor Gray
                        Write-Host $result.RuntimeStatus -ForegroundColor Gray
                    }
                }

                if ($result.RegistryStatus -and $result.RegistryStatus -ne 'N/A') {
                    Write-Host "  Registry:     " -NoNewline -ForegroundColor Gray
                    Write-Host $result.RegistryStatus -ForegroundColor Gray
                }

                # Show Performance Impact
                Write-Host "  Impact:       " -NoNewline -ForegroundColor Gray
                $impactColor = switch ($result.Impact) {
                    'High' { 'Red' }
                    'Medium' { 'Yellow' }
                    'Low' { 'Green' }
                    default { 'Gray' }
                }
                Write-Host $result.Impact -ForegroundColor $impactColor

                # Show Recommendation if action needed
                if ($result.ActionNeeded -match 'Yes|Consider' -and $result.Recommendation) {
                    Write-Host "  Action:       " -NoNewline -ForegroundColor Gray
                    Write-Host $result.Recommendation -ForegroundColor Yellow
                }
            }

            # Add educational note about runtime vs registry
            if ($script:RuntimeState.APIAvailable) {
                Write-Host "`n$(Get-StatusIcon -Name Info) " -NoNewline -ForegroundColor Cyan
                Write-Host "Runtime Status Guide:" -ForegroundColor White
                Write-Host "  $(Get-StatusIcon -Name Success) Active / Active (details)" -ForegroundColor Green -NoNewline
                Write-Host " - Protection is running (protected)" -ForegroundColor Gray
                Write-Host "  $(Get-StatusIcon -Name Cross) Inactive / Inactive (details)" -ForegroundColor Red -NoNewline
                Write-Host " - Protection is NOT running (vulnerable)" -ForegroundColor Gray
                Write-Host "  $(Get-StatusIcon -Name Info) Not Needed (HW Immune)" -ForegroundColor Cyan -NoNewline
                Write-Host " - Hardware immunity (no mitigation needed)" -ForegroundColor Gray
                Write-Host "  $(Get-StatusIcon -Name Info) Not Supported" -ForegroundColor Gray -NoNewline
                Write-Host " - Feature not available on this hardware" -ForegroundColor Gray
                Write-Host "  $(Get-StatusIcon -Name Info) N/A" -ForegroundColor Gray -NoNewline
                Write-Host " - No runtime detection (check registry)" -ForegroundColor Gray
                Write-Host "`n  Note: Status may include additional details in parentheses (e.g., version, method)" -ForegroundColor DarkGray
            }
        }

        'Detailed' {
            # Detailed table with more columns (Category, Status, CVE, Platform, Impact, PrerequisiteFor)
            Write-Host ("{0,-30} {1,-12} {2,-12} {3,-25} {4,-12} {5,-8} {6}" -f "Mitigation", "Category", "Status", "CVE", "Platform", "Impact", "Required For") -ForegroundColor Gray
            Write-Host ("{0,-30} {1,-12} {2,-12} {3,-25} {4,-12} {5,-8} {6}" -f ("-" * 29), ("-" * 11), ("-" * 11), ("-" * 24), ("-" * 11), ("-" * 7), ("-" * 35)) -ForegroundColor DarkGray

            if ($useAnsi) {
                # PowerShell 7+ with ANSI color codes
                $ansiReset = "`e[0m"
                $ansiGreen = "`e[32m"
                $ansiRed = "`e[31m"

                $ansiYellow = "`e[33m"
                $ansiGray = "`e[90m"

                foreach ($result in $Results) {
                    # Color based on Category + ActionNeeded, not just status
                    $lineAnsi = if ($result.OverallStatus -in @('Protected', 'Active')) {
                        $ansiGreen
                    }
                    elseif ($result.ActionNeeded -match 'Yes - Critical') {
                        $ansiRed  # Critical vulnerability
                    }
                    elseif ($result.ActionNeeded -eq 'Consider' -or $result.Category -eq 'Optional') {
                        $ansiYellow  # Optional or recommended
                    }
                    elseif ($result.OverallStatus -eq 'Vulnerable') {
                        $ansiRed  # Vulnerable but not optional
                    }
                    else {
                        $ansiGray
                    }

                    # Truncate mitigation name if too long
                    $nameDisplay = if ($result.Name.Length -gt 30) {
                        $result.Name.Substring(0, 27) + "..."
                    }
                    else {
                        $result.Name
                    }

                    # Truncate CVE if too long
                    $cveDisplay = if ($result.CVE -and $result.CVE.Length -gt 25) {
                        $result.CVE.Substring(0, 22) + "..."
                    }
                    else {
                        $result.CVE
                    }

                    # Get platform and prerequisiteFor from mitigation definition
                    $mitigationDef = (Get-SideChannelMitigationDefinition) | Where-Object { $_.Id -eq $result.Id }
                    $platformDisplay = if ($mitigationDef -and $mitigationDef.Platform) { $mitigationDef.Platform } else { 'All' }
                    $prereqForDisplay = if ($mitigationDef -and $mitigationDef.ContainsKey('PrerequisiteFor') -and $mitigationDef.PrerequisiteFor) {
                        if ($mitigationDef.PrerequisiteFor.Length -gt 35) {
                            $mitigationDef.PrerequisiteFor.Substring(0, 32) + "..."
                        }
                        else {
                            $mitigationDef.PrerequisiteFor
                        }
                    }
                    else { '-' }

                    $line = "{0,-30} {1,-12} {2,-12} {3,-25} {4,-12} {5,-8} {6}" -f $nameDisplay, $result.Category, $result.OverallStatus, $cveDisplay, $platformDisplay, $result.Impact, $prereqForDisplay
                    Write-Host "$lineAnsi$line$ansiReset"
                }
            }
            else {
                # PowerShell 5.1 fallback
                foreach ($result in $Results) {
                    # Color based on Category + ActionNeeded, not just status
                    $lineColor = if ($result.OverallStatus -in @('Protected', 'Active')) {
                        'Green'
                    }
                    elseif ($result.ActionNeeded -match 'Yes - Critical') {
                        'Red'  # Critical vulnerability
                    }
                    elseif ($result.ActionNeeded -eq 'Consider' -or $result.Category -eq 'Optional') {
                        'Yellow'  # Optional or recommended
                    }
                    elseif ($result.OverallStatus -eq 'Vulnerable') {
                        'Red'  # Vulnerable but not optional
                    }
                    else {
                        'Gray'
                    }

                    # Truncate mitigation name if too long
                    $nameDisplay = if ($result.Name.Length -gt 30) {
                        $result.Name.Substring(0, 27) + "..."
                    }
                    else {
                        $result.Name
                    }

                    # Truncate CVE if too long
                    $cveDisplay = if ($result.CVE -and $result.CVE.Length -gt 25) {
                        $result.CVE.Substring(0, 22) + "..."
                    }
                    else {
                        $result.CVE
                    }

                    # Get platform and prerequisiteFor from mitigation definition
                    $mitigationDef = (Get-SideChannelMitigationDefinition) | Where-Object { $_.Id -eq $result.Id }
                    $platformDisplay = if ($mitigationDef -and $mitigationDef.Platform) { $mitigationDef.Platform } else { 'All' }
                    $prereqForDisplay = if ($mitigationDef -and $mitigationDef.ContainsKey('PrerequisiteFor') -and $mitigationDef.PrerequisiteFor) {
                        if ($mitigationDef.PrerequisiteFor.Length -gt 35) {
                            $mitigationDef.PrerequisiteFor.Substring(0, 32) + "..."
                        }
                        else {
                            $mitigationDef.PrerequisiteFor
                        }
                    }
                    else { '-' }

                    $line = "{0,-30} {1,-12} {2,-12} {3,-25} {4,-12} {5,-8} {6}" -f $nameDisplay, $result.Category, $result.OverallStatus, $cveDisplay, $platformDisplay, $result.Impact, $prereqForDisplay
                    Write-Host $line -ForegroundColor $lineColor
                }
            }
        }

        'Simple' {
            # Simple table view (4 columns)
            Write-Host ("{0,-45} {1,-20} {2,-26} {3}" -f "Mitigation", "Status", "Action Needed", "Impact") -ForegroundColor Gray
            Write-Host ("{0,-45} {1,-20} {2,-26} {3}" -f ("-" * 44), ("-" * 19), ("-" * 25), ("-" * 9)) -ForegroundColor DarkGray

            if ($useAnsi) {
                # PowerShell 7+ with ANSI color codes for entire line
                $ansiReset = "`e[0m"
                $ansiGreen = "`e[32m"
                $ansiRed = "`e[31m"
                $ansiBrightRed = "`e[91m"  # Bright red for critical vulnerabilities
                $ansiYellow = "`e[93m"  # Bright yellow for better visibility
                $ansiGray = "`e[90m"

                foreach ($result in $Results) {
                    # Determine ANSI color based on ActionNeeded and Category (same logic as Detailed view)
                    $lineAnsi = if ($result.OverallStatus -in @('Protected', 'Active')) {
                        $ansiGreen
                    }
                    elseif ($result.ActionNeeded -match 'Yes - Critical') {
                        $ansiBrightRed  # Critical vulnerability requiring immediate action
                    }
                    elseif ($result.ActionNeeded -eq 'Consider' -or $result.Category -eq 'Optional') {
                        $ansiYellow  # Optional or recommended - evaluate for environment
                    }
                    elseif ($result.OverallStatus -eq 'Vulnerable') {
                        $ansiRed  # Vulnerable but not optional
                    }
                    else {
                        $ansiGray
                    }

                    # Format the entire line
                    $line = "{0,-45} {1,-20} {2,-26} {3}" -f $result.Name, $result.OverallStatus, $result.ActionNeeded, $result.Impact

                    # Output with color for entire line
                    Write-Host "$lineAnsi$line$ansiReset"
                }
            }
            else {
                # PowerShell 5.1 fallback - use VT100 if available or plain text
                foreach ($result in $Results) {
                    # Format the entire line as a single string
                    $line = "{0,-45} {1,-20} {2,-26} {3}" -f $result.Name, $result.OverallStatus, $result.ActionNeeded, $result.Impact

                    # Determine color based on ActionNeeded and Category (same logic as Detailed view)
                    $lineColor = if ($result.OverallStatus -in @('Protected', 'Active')) {
                        'Green'
                    }
                    elseif ($result.ActionNeeded -match 'Yes - Critical') {
                        'Red'  # Critical vulnerability requiring immediate action
                    }
                    elseif ($result.ActionNeeded -eq 'Consider' -or $result.Category -eq 'Optional') {
                        'Yellow'  # Optional or recommended - evaluate for environment
                    }
                    elseif ($result.OverallStatus -eq 'Vulnerable') {
                        'Red'  # Vulnerable but not optional
                    }
                    else {
                        'Gray'
                    }

                    Write-Host $line -ForegroundColor $lineColor
                }
            }
        }
    }
}