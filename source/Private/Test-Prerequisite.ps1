function Test-Prerequisite {
    <#
    .SYNOPSIS
        Tests if all prerequisites for the tool are met.

    .DESCRIPTION
        Verifies administrator privileges, Windows OS, and other requirements before running the assessment.

    .PARAMETER Mitigation
        The mitigation definition hashtable containing registry path and expected values.

    .EXAMPLE
        Test-Prerequisite

        Checks if all prerequisites are satisfied.
    #>
    param([hashtable]$Mitigation)

    $status = 'Not Met'
    $currentValue = $null
    $overallStatus = 'Missing'

    switch ($Mitigation.Id) {
        'UEFI' {
            $status = if ($script:HardwareInfo.IsUEFI) { 'Active' } else { 'Not Present' }
            $overallStatus = if ($script:HardwareInfo.IsUEFI) { 'Active' } else { 'Missing' }
            $currentValue = $script:HardwareInfo.IsUEFI
        }
        'SecureBoot' {
            if ($script:HardwareInfo.SecureBootEnabled) {
                $status = 'Active'
                $overallStatus = 'Protected'
            }
            elseif ($script:HardwareInfo.SecureBootCapable) {
                $status = 'Inactive (Capable)'
                $overallStatus = 'Vulnerable'
            }
            else {
                $status = 'Not Supported'
                $overallStatus = 'Missing'
            }
            $currentValue = $script:HardwareInfo.SecureBootEnabled
        }
        'TPM' {
            if ($script:HardwareInfo.TPMPresent) {
                $status = "Active ($($script:HardwareInfo.TPMVersion))"
                $overallStatus = 'Protected'
            }
            else {
                $status = 'Not Present'
                $overallStatus = 'Missing'
            }
            $currentValue = $script:HardwareInfo.TPMVersion
        }
        'VTx' {
            if ($script:HardwareInfo.VTxEnabled) {
                $status = 'Active'
                $overallStatus = 'Protected'
            }
            else {
                $status = 'Not Supported'
                $overallStatus = 'Missing'
            }
            $currentValue = $script:HardwareInfo.VTxEnabled
        }
        'IOMMU' {
            if ($script:HardwareInfo.IOMMUSupport) {
                $status = 'Active'
                $overallStatus = 'Protected'
            }
            else {
                $status = 'Not Supported'
                $overallStatus = 'Missing'
            }
            $currentValue = $script:HardwareInfo.IOMMUSupport
        }
    }

    # Customize recommendation based on platform type
    $recommendation = $Mitigation.Recommendation
    if ($overallStatus -in @('Missing', 'Vulnerable') -and $script:PlatformInfo.Type -eq 'VMwareGuest') {
        # Provide VMware-specific guidance
        switch ($Mitigation.Id) {
            'SecureBoot' {
                $recommendation = "Enable Secure Boot in VM settings (VM must use EFI firmware). Power off VM → Edit Settings → VM Options → Boot Options → Enable Secure Boot"
            }
            'TPM' {
                $recommendation = "Add vTPM to VM: Power off VM → Edit Settings → Add New Device → Trusted Platform Module → Add"
            }
            'VTx' {
                $recommendation = "Expose hardware-assisted virtualization to VM: Power off VM → Edit Settings → CPU → Enable 'Expose hardware assisted virtualization to the guest OS'"
            }
            'IOMMU' {
                $recommendation = "Enable IOMMU passthrough in VM: Power off VM → Edit Settings → VM Options → Advanced → Enable 'Enable IOMMU'"
            }
        }
    }
    elseif ($overallStatus -in @('Missing', 'Vulnerable') -and $script:PlatformInfo.Type -eq 'HyperVGuest') {
        # Provide Hyper-V-specific guidance (existing behavior)
        switch ($Mitigation.Id) {
            'SecureBoot' {
                $recommendation = "Enable Secure Boot in VM settings (VM must use Generation 2). PowerShell: Set-VMFirmware -VMName '<vmname>' -EnableSecureBoot On"
            }
            'TPM' {
                $recommendation = "Enable vTPM for VM (requires Generation 2, Key Protector). PowerShell: Enable-VMTPM -VMName '<vmname>'"
            }
            'VTx' {
                $recommendation = "Expose virtualization extensions to VM: Set-VMProcessor -VMName '<vmname>' -ExposeVirtualizationExtensions `$true"
            }
            'IOMMU' {
                $recommendation = "IOMMU is automatically available for Generation 2 VMs with nested virtualization enabled"
            }
        }
    }

    return [PSCustomObject]@{
        Id             = $Mitigation.Id
        Name           = $Mitigation.Name
        CVE            = $Mitigation.CVE
        Category       = 'Prerequisite'
        RegistryStatus = 'N/A'
        RuntimeStatus  = $status
        OverallStatus  = $overallStatus
        ActionNeeded   = if ($overallStatus -eq 'Protected' -or $overallStatus -eq 'Active') { 'No' } else { 'Configure in Firmware' }
        CurrentValue   = $currentValue
        ExpectedValue  = $Mitigation.EnabledValue
        Impact         = 'None'
        Description    = $Mitigation.Description
        Recommendation = $recommendation
        RegistryPath   = $Mitigation.RegistryPath
        RegistryName   = $Mitigation.RegistryName
        URL            = if ($Mitigation.ContainsKey('URL')) { $Mitigation.URL } else { $null }
    }
}