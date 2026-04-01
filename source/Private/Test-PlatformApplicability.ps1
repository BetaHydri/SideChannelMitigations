function Test-PlatformApplicability {
    <#
    .SYNOPSIS
        Determines if a mitigation applies to the current platform.

    .DESCRIPTION
        Checks the platform type against the mitigation definition to determine if the mitigation is applicable to this system.

    .PARAMETER TargetPlatform
        The platform type to check applicability against (All, Physical, HyperVHost, etc.).

    .EXAMPLE
        Test-PlatformApplicability -Mitigation @{Platform="All"}

        Checks if a mitigation applies to the current platform.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TargetPlatform
    )

    switch ($TargetPlatform) {
        'All' { return $true }
        'Physical' { return $script:PlatformInfo.Type -in @('Physical', 'HyperVHost') }
        'HyperVHost' { return $script:PlatformInfo.Type -eq 'HyperVHost' }
        'HyperVGuest' { return $script:PlatformInfo.Type -eq 'HyperVGuest' }
        'VMwareGuest' { return $script:PlatformInfo.Type -eq 'VMwareGuest' }
        'VirtualMachine' { return $script:PlatformInfo.Type -match 'Guest$|VirtualMachine' }
        default { return $true }
    }
}