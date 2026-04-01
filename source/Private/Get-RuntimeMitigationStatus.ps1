function Get-RuntimeMitigationStatus {
    <#
    .SYNOPSIS
        Queries kernel runtime state for mitigation status.

    .DESCRIPTION
        Checks the real-time kernel mitigation flags to determine if a specific
        side-channel mitigation is actively enforced by the CPU and OS.

    .PARAMETER MitigationId
        The identifier of the mitigation to check (e.g., BTI, SSBD, KVAS, MDS).

    .EXAMPLE
        Get-RuntimeMitigationStatus -MitigationId 'BTI'

        Checks runtime status of Branch Target Injection mitigation.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$MitigationId
    )

    if (-not $script:RuntimeState.APIAvailable) {
        return 'N/A'
    }

    switch ($MitigationId) {
        'BTI' {
            if ($script:RuntimeState.Flags['EnhancedIBRS']) { return 'Active (Enhanced IBRS)' }
            if ($script:RuntimeState.Flags['RetpolineEnabled']) { return 'Active (Retpoline)' }
            if ($script:RuntimeState.Flags['BTIEnabled']) { return 'Active' }
            return 'Inactive'
        }
        'SSBD' {
            if ($script:RuntimeState.Flags['SSBDSystemWide']) { return 'Active' }
            return 'Inactive'
        }
        'KVAS' {
            if ($script:RuntimeState.Flags['RDCLHardwareProtected']) { return 'Not Needed (HW Immune)' }
            if ($script:RuntimeState.Flags['KVAShadowEnabled']) { return 'Active' }
            return 'Inactive'
        }
        'MDS' {
            if ($script:RuntimeState.Flags['MDSHardwareProtected']) { return 'Not Needed (HW Immune)' }
            if ($script:RuntimeState.Flags['MBClearEnabled']) { return 'Active' }
            try {
                $regValue = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' -Name MDSMitigationLevel -ErrorAction SilentlyContinue
                if ($regValue -and $regValue.MDSMitigationLevel -eq 1) {
                    return 'Inactive (Microcode Update Required)'
                }
            }
            catch {
                Write-Debug "Registry check failed for MDS: $_"
            }
            return 'Inactive'
        }
        'L1TF' {
            if (-not $script:RuntimeState.Flags['L1DFlushSupported']) {
                return 'Not Supported'
            }
            try {
                $regValue = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' -Name L1TFMitigationLevel -ErrorAction SilentlyContinue
                if ($regValue -and $regValue.L1TFMitigationLevel -eq 1) {
                    return 'Active'
                }
            }
            catch {
                Write-Debug "Registry check failed for L1TF: $_"
            }
            return 'Inactive'
        }
        'SBDR' {
            if ($script:RuntimeState.Flags['SBDRHardwareProtected']) {
                return 'Not Needed (HW Immune)'
            }
            if ($script:RuntimeState.Flags['FBClearEnabled']) {
                return 'Active'
            }
            try {
                $regValue = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' -Name SBDRMitigationLevel -ErrorAction SilentlyContinue
                if ($regValue -and $regValue.SBDRMitigationLevel -eq 1) {
                    return 'Inactive (Microcode Update Required)'
                }
            }
            catch {
                Write-Debug "Registry check failed for SBDR: $_"
            }
            return 'Inactive'
        }
        'FBSDP' {
            if ($script:RuntimeState.Flags['FBSDPHardwareProtected']) {
                return 'Not Needed (HW Immune)'
            }
            if ($script:RuntimeState.Flags['FBClearEnabled']) {
                return 'Active'
            }
            try {
                $regValue = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' -Name SBDRMitigationLevel -ErrorAction SilentlyContinue
                if ($regValue -and $regValue.SBDRMitigationLevel -eq 1) {
                    return 'Inactive (Microcode Update Required)'
                }
            }
            catch {
                Write-Debug "Registry check failed for FBSDP: $_"
            }
            return 'Inactive'
        }
        'PSDP' {
            if ($script:RuntimeState.Flags['PSDPHardwareProtected']) {
                return 'Not Needed (HW Immune)'
            }
            if ($script:RuntimeState.Flags['FBClearEnabled']) {
                return 'Active'
            }
            try {
                $regValue = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' -Name PredictiveStoreForwardingDisable -ErrorAction SilentlyContinue
                if ($regValue -and $regValue.PredictiveStoreForwardingDisable -eq 1) {
                    return 'Inactive (Microcode Update Required)'
                }
            }
            catch {
                Write-Debug "Registry check failed for PSDP: $_"
            }
            return 'Inactive'
        }
        default { return 'N/A' }
    }
}