function Invoke-MitigationAssessment {
    <#
    .SYNOPSIS
        Performs the core mitigation assessment logic.

    .DESCRIPTION
        Iterates through all applicable mitigations, checks registry and runtime status, and returns assessment result objects.

    .EXAMPLE
        Invoke-MitigationAssessment

        Runs the mitigation assessment and returns results.
    #>

    Write-Log "Starting mitigation assessment..." -Level Info

    $mitigations = Get-SideChannelMitigationDefinition
    $results = @()

    foreach ($mitigation in $mitigations) {
        # Check platform applicability
        if (-not (Test-PlatformApplicability -TargetPlatform $mitigation.Platform)) {
            Write-Log "Skipping $($mitigation.Name) - not applicable to $($script:PlatformInfo.Type)" -Level Debug
            continue
        }

        $result = Test-Mitigation -Mitigation $mitigation
        $results += $result
    }

    Write-Log "Assessment complete: $($results.Count) mitigations evaluated" -Level Success
    return $results
}