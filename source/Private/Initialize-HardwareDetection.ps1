function Initialize-HardwareDetection {
    <#
    .SYNOPSIS
        Detects hardware security capabilities and prerequisites.

    .DESCRIPTION
        Probes UEFI, Secure Boot, TPM, and CPU virtualization capabilities
        to populate the hardware info state.

    .EXAMPLE
        Initialize-HardwareDetection

        Populates the hardware detection state variables.
    #>

    Write-Log -Message "Detecting hardware security features..." -Level Debug

    # Check UEFI
    try {
        $firmwareType = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State" -Name "UEFISecureBootEnabled" -ErrorAction SilentlyContinue
        $script:HardwareInfo.IsUEFI = $null -ne $firmwareType
    }
    catch {
        $script:HardwareInfo.IsUEFI = $false
    }

    # Check Secure Boot
    try {
        $secureBootState = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State" -Name "UEFISecureBootEnabled" -ErrorAction SilentlyContinue
        if ($secureBootState) {
            $script:HardwareInfo.SecureBootEnabled = $secureBootState.UEFISecureBootEnabled -eq 1
            $script:HardwareInfo.SecureBootCapable = $true
        }
    }
    catch {
        $script:HardwareInfo.SecureBootEnabled = $false
    }

    # Check TPM
    try {
        $tpm = Get-CimInstance -Namespace "Root\cimv2\Security\MicrosoftTpm" -ClassName "Win32_Tpm" -ErrorAction SilentlyContinue
        if ($tpm) {
            $script:HardwareInfo.TPMPresent = $true
            $specVersion = $tpm.SpecVersion
            if ($specVersion -match '^(\d+\.\d+)') {
                $script:HardwareInfo.TPMVersion = $matches[1]
            }
            else {
                $script:HardwareInfo.TPMVersion = $specVersion
            }
        }
        else {
            # Fallback check using CIM
            $tpmCim = Get-CimInstance -Namespace "Root\cimv2\Security\MicrosoftTpm" -ClassName "Win32_Tpm" -ErrorAction SilentlyContinue
            if ($tpmCim) {
                $script:HardwareInfo.TPMPresent = $true
                $script:HardwareInfo.TPMVersion = "2.0"
            }
        }
    }
    catch {
        $script:HardwareInfo.TPMPresent = $false
    }

    # Check CPU Virtualization (VT-x/AMD-V)
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        if ($cpu.VirtualizationFirmwareEnabled -eq $true) {
            $script:HardwareInfo.VTxEnabled = $true
        }
        else {
            $hvPresent = $false

            try {
                $hvReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" -Name "HypervisorPresent" -ErrorAction SilentlyContinue
                if ($hvReg -and $hvReg.HypervisorPresent -eq 1) {
                    $hvPresent = $true
                }
            }
            catch {
                Write-Debug "Hypervisor registry check failed: $($_.Exception.Message)"
            }

            if (-not $hvPresent) {
                try {
                    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
                    if ($cs.HypervisorPresent -eq $true) {
                        $hvPresent = $true
                    }
                }
                catch {
                    Write-Debug "ComputerSystem hypervisor check failed: $($_.Exception.Message)"
                }
            }

            $script:HardwareInfo.VTxEnabled = $hvPresent
        }
    }
    catch {
        $script:HardwareInfo.VTxEnabled = $false
    }

    # Check IOMMU/VT-d
    try {
        $iommuRegistry = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\iommu" -ErrorAction SilentlyContinue
        if ($iommuRegistry) {
            $script:HardwareInfo.IOMMUSupport = $true
        }
        else {
            $deviceGuard = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue
            if ($deviceGuard -and $deviceGuard.AvailableSecurityProperties -contains 7) {
                $script:HardwareInfo.IOMMUSupport = $true
            }
        }
    }
    catch {
        $script:HardwareInfo.IOMMUSupport = $false
    }

    # Check VBS capability
    try {
        $deviceGuard = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue
        if ($deviceGuard) {
            $script:HardwareInfo.VBSCapable = $script:HardwareInfo.IsUEFI -and
                $script:HardwareInfo.SecureBootCapable -and
                $script:HardwareInfo.VTxEnabled -and
                $script:HardwareInfo.IOMMUSupport

            $script:HardwareInfo.HVCICapable = $script:HardwareInfo.VBSCapable
        }
    }
    catch {
        $script:HardwareInfo.VBSCapable = $false
        $script:HardwareInfo.HVCICapable = $false
    }

    Write-Log -Message "Hardware detection complete" -Level Success
}