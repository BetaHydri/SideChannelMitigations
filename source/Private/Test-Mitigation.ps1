function Test-Mitigation {
    <#
    .SYNOPSIS
        Tests the current state of a specific mitigation.

    .DESCRIPTION
        Reads registry values and runtime state for a given mitigation definition and returns a result object with status details.

    .PARAMETER Mitigation
        The mitigation definition hashtable containing registry path and expected values.

    .EXAMPLE
        Test-Mitigation -Mitigation $mitigationDefinition

        Tests a single mitigation and returns its status.
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Mitigation
    )

    # Handle prerequisites separately
    if ($Mitigation.ContainsKey('IsPrerequisite') -and $Mitigation.IsPrerequisite) {
        return Test-Prerequisite -Mitigation $Mitigation
    }

    # Check hardware requirements
    if ($Mitigation.ContainsKey('HardwareRequired') -and $Mitigation.HardwareRequired) {
        $hwCapable = Test-HardwareCapability -Requirement $Mitigation.HardwareRequired
        if (-not $hwCapable) {
            return [PSCustomObject]@{
                Id             = $Mitigation.Id
                Name           = $Mitigation.Name
                CVE            = $Mitigation.CVE
                Category       = $Mitigation.Category
                RegistryStatus = 'N/A'
                RuntimeStatus  = 'Hardware Not Supported'
                OverallStatus  = 'Not Applicable'
                ActionNeeded   = 'No'
                CurrentValue   = $null
                ExpectedValue  = $Mitigation.EnabledValue
                Impact         = $Mitigation.Impact
                Description    = $Mitigation.Description
                Recommendation = "Hardware prerequisites not met: $($Mitigation.HardwareRequired)"
                RegistryPath   = $Mitigation.RegistryPath
                RegistryName   = $Mitigation.RegistryName
                URL            = if ($Mitigation.ContainsKey('URL')) { $Mitigation.URL } else { $null }
            }
        }
    }

    # Get current registry value
    $currentValue = $null
    $registryStatus = 'Not Configured'

    try {
        $regItem = Get-ItemProperty -Path $Mitigation.RegistryPath -Name $Mitigation.RegistryName -ErrorAction Stop
        $currentValue = $regItem.($Mitigation.RegistryName)

        # Compare values
        if (Compare-MitigationValue -Current $currentValue -Expected $Mitigation.EnabledValue -RegistryName $Mitigation.RegistryName) {
            $registryStatus = 'Enabled'
        }
        else {
            $registryStatus = 'Disabled'
        }
    }
    catch {
        $registryStatus = 'Not Configured'
    }

    # Get runtime status
    $runtimeStatus = 'N/A'
    if ($Mitigation.RuntimeDetection) {
        $runtimeStatus = Get-RuntimeMitigationStatus -MitigationId $Mitigation.RuntimeDetection
    }

    # Determine overall status
    $overallStatus = Get-OverallStatus -RegistryStatus $registryStatus -RuntimeStatus $runtimeStatus

    # Determine action needed
    $actionNeeded = Get-ActionNeeded -Category $Mitigation.Category -OverallStatus $overallStatus

    return [PSCustomObject]@{
        Id             = $Mitigation.Id
        Name           = $Mitigation.Name
        CVE            = $Mitigation.CVE
        Category       = $Mitigation.Category
        RegistryStatus = $registryStatus
        RuntimeStatus  = $runtimeStatus
        OverallStatus  = $overallStatus
        ActionNeeded   = $actionNeeded
        CurrentValue   = $currentValue
        ExpectedValue  = $Mitigation.EnabledValue
        Impact         = $Mitigation.Impact
        Description    = $Mitigation.Description
        Recommendation = $Mitigation.Recommendation
        RegistryPath   = $Mitigation.RegistryPath
        RegistryName   = $Mitigation.RegistryName
        URL            = if ($Mitigation.ContainsKey('URL')) { $Mitigation.URL } else { $null }
    }
}