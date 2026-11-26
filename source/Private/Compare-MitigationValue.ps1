function Compare-MitigationValue {
    <#
    .SYNOPSIS
        Compares current registry value against expected mitigation value.

    .DESCRIPTION
        Compares the current registry value with the expected value for a specific mitigation. Handles special cases for FeatureSettingsOverride bit fields and REG_BINARY byte arrays.

    .PARAMETER Current
        The current registry value to compare against the expected value.

    .PARAMETER Expected
        The expected registry value that indicates proper mitigation configuration.

    .PARAMETER RegistryName
        The registry value name, used to identify special handling rules.

    .EXAMPLE
        Compare-MitigationValue -Current 1 -Expected 1 -RegistryName "TestReg"

        Compares a simple registry value match.
    #>
    param(
        [object]$Current,
        [object]$Expected,
        [string]$RegistryName
    )

    # Special handling for FeatureSettingsOverride
    # This registry value is a bit field with disable and enable flags
    # Per Microsoft KB4072698, recommended values to ENABLE system-wide mitigations:
    #   0x48 (72)          = Basic mitigations, Hyper-Threading enabled
    #   0x2048 (8264)      = Basic mitigations, Hyper-Threading disabled variant
    #   0x800000 (8388608) = BHI mitigation (CVE-2022-0001), combined with the above by OR
    #   0x4000000          = AMD CVE-2023-20569, combined with the above by OR
    # Bit 0 (0x1) disables Spectre v2 and bit 1 (0x2) disables Meltdown mitigations - must be CLEAR.
    # Bit 3 (0x8) enables SSBD system-wide - must be SET. Value 0 leaves it to Windows per process.
    # Checked bitwise so every documented combination (72, 8264, 0x800048, 0x802048, ...) passes.
    if ($RegistryName -eq 'FeatureSettingsOverride') {
        # If value doesn't exist, mitigations are NOT enabled system-wide
        if ($null -eq $Current) { return $false }

        $value = [int64]$Current
        $ssbdEnabled = ($value -band 0x8) -ne 0
        $nothingDisabled = ($value -band 0x3) -eq 0
        return ($ssbdEnabled -and $nothingDisabled)
    }

    if ($null -eq $Current) { return $false }

    # Handle REG_BINARY type (byte array) - convert to uint64
    # This happens after reboot when Windows converts MitigationOptions to REG_BINARY
    if ($Current -is [byte[]]) {
        if ($Current.Length -ge 8) {
            # Convert first 8 bytes to uint64 (little-endian)
            # Windows stores MitigationOptions as variable-length binary, we only need first 8 bytes
            $Current = [BitConverter]::ToUInt64($Current, 0)
        }
        elseif ($Current.Length -ge 4) {
            # Convert first 4 bytes to uint32
            $Current = [BitConverter]::ToUInt32($Current, 0)
        }
        else {
            # Unsupported byte array length
            return $false
        }
    }

    # Handle hex string comparisons for large values
    if ($Expected -is [long] -or $Expected -is [uint64]) {
        # For MitigationOptions, check if core flag is set (bitwise AND)
        if ($RegistryName -eq 'MitigationOptions' -and $Current -is [uint64]) {
            $coreFlagPresent = ($Current -band $Expected) -eq $Expected
            return $coreFlagPresent
        }
        return $Current -eq $Expected
    }

    return $Current -eq $Expected
}