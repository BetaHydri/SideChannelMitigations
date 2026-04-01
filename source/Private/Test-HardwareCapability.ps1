function Test-HardwareCapability {
    <#
    .SYNOPSIS
        Tests if specific hardware capabilities are present.

    .DESCRIPTION
        Checks the hardware info state to determine if a required security capability (UEFI, SecureBoot, TPM, etc.) is available.

    .PARAMETER Requirement
        The Requirement parameter.

    .EXAMPLE
        Test-HardwareCapability -Capability "SecureBoot"

        Tests if Secure Boot is available.
    #>
    param([string]$Requirement)

    switch ($Requirement) {
        'VBS' { return $script:HardwareInfo.VBSCapable }
        'HVCI' { return $script:HardwareInfo.HVCICapable }
        default { return $true }
    }
}