function Export-SideChannelAssessment {
    <#
    .SYNOPSIS
        Exports assessment results to a CSV file.

    .DESCRIPTION
        Writes the mitigation assessment results to a CSV file for reporting and documentation purposes.
        The CSV file is automatically named using the pattern:
        SideChannelAssessment_<ComputerName>_<yyyyMMdd_HHmmss>.csv

    .PARAMETER Results
        The array of mitigation assessment result objects to process.

    .PARAMETER Path
        The destination folder path where the CSV file will be created.
        The filename is generated automatically.

    .EXAMPLE
        Export-SideChannelAssessment -Results $results -Path 'C:\Reports'

        Exports results to C:\Reports\SideChannelAssessment_SERVER01_20260401_120000.csv
    #>
    param(
        [array]$Results,
        [string]$Path
    )

    try {
        # Ensure destination folder exists
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }

        # Build auto-generated CSV filename
        $fileName = "SideChannelAssessment_{0}_{1}.csv" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd_HHmmss')
        $filePath = Join-Path -Path $Path -ChildPath $fileName

        # Enrich results with full untruncated data from mitigation definitions
        $enrichedResults = @()
        $mitigationDefs = Get-SideChannelMitigationDefinition

        foreach ($result in $Results) {
            $mitigationDef = $mitigationDefs | Where-Object { $_.Id -eq $result.Id }

            # Create enriched object with full data (no truncation)
            $enrichedResult = [PSCustomObject]@{
                Id              = $result.Id
                Name            = $result.Name
                Category        = $result.Category
                Status          = $result.OverallStatus
                RegistryStatus  = $result.RegistryStatus
                RuntimeStatus   = $result.RuntimeStatus
                ActionNeeded    = $result.ActionNeeded
                CVE             = $result.CVE
                Platform        = if ($mitigationDef -and $mitigationDef.Platform) { $mitigationDef.Platform } else { 'All' }
                Impact          = $result.Impact
                PrerequisiteFor = if ($mitigationDef -and $mitigationDef.ContainsKey('PrerequisiteFor') -and $mitigationDef.PrerequisiteFor) { $mitigationDef.PrerequisiteFor } else { '-' }
                CurrentValue    = $result.CurrentValue
                ExpectedValue   = $result.ExpectedValue
                Description     = $result.Description
                Recommendation  = $result.Recommendation
                RegistryPath    = $result.RegistryPath
                RegistryName    = $result.RegistryName
                URL             = if ($result.PSObject.Properties.Name -contains 'URL') { $result.URL } else { '' }
            }

            $enrichedResults += $enrichedResult
        }

        # Export with semicolon delimiter (instead of comma) to avoid conflicts with comma-separated lists in data
        # PowerShell 5.1 doesn't support -Delimiter parameter, so we need version-specific handling
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            # PowerShell 6+ (Core/7+) - use -Delimiter parameter
            $enrichedResults | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8 -Delimiter ';'
        }
        else {
            # PowerShell 5.1 - manually convert to CSV with semicolon delimiter
            $csvContent = $enrichedResults | ConvertTo-Csv -NoTypeInformation
            # Replace commas with semicolons in the CSV (careful to preserve commas within quoted fields)
            $csvContent = $csvContent | ForEach-Object {
                # This regex replaces commas that are not inside quotes
                $_ -replace ',(?=(?:[^"]*"[^"]*")*[^"]*$)', ';'
            }
            $csvContent | Set-Content -Path $filePath -Encoding UTF8
        }
        Write-Log "Assessment exported to: $filePath" -Level Success
        Write-Host "`n$(Get-StatusIcon -Name Success) Assessment exported successfully to: $filePath" -ForegroundColor Green
    }
    catch {
        Write-Log "Export failed: $($_.Exception.Message)" -Level Error
        Write-Host "$(Get-StatusIcon -Name Error) Export failed: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # Return the full path of the exported file for callers
    return $filePath
}