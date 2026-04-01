function Get-OverallStatus {
    <#
    .SYNOPSIS
        Determines overall mitigation protection status.

    .DESCRIPTION
        Evaluates registry and runtime status to determine if a mitigation is Protected, Vulnerable, or Unknown. Runtime status takes priority over registry status.

    .PARAMETER RegistryStatus
        The registry-based mitigation configuration status.

    .PARAMETER RuntimeStatus
        The kernel runtime mitigation activation status.

    .EXAMPLE
        Get-OverallStatus -RegistryStatus "Enabled" -RuntimeStatus "Active"

        Returns the overall protection status.
    #>
    param(
        [string]$RegistryStatus,
        [string]$RuntimeStatus
    )

    # Priority: Runtime status > Registry status
    if ($RuntimeStatus -ne 'N/A') {
        # Use word boundaries to avoid "Inactive" matching "Active"
        if ($RuntimeStatus -match '^(Active|Immune|Supported|Not Needed)') {
            return 'Protected'
        }
        else {
            return 'Vulnerable'
        }
    }

    # Fallback to registry
    switch ($RegistryStatus) {
        'Enabled' { return 'Protected' }
        'Disabled' { return 'Vulnerable' }
        'Not Configured' { return 'Vulnerable' }  # Not configured = not protected
        default { return 'Unknown' }
    }
}