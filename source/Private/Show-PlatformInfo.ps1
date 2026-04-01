function Show-PlatformInfo {
    <#
    .SYNOPSIS
        Displays platform detection information.

    .DESCRIPTION
        Shows the detected platform type, CPU vendor, OS version, and hardware capabilities in a formatted console output.

    .EXAMPLE
        Show-PlatformInfo

        Displays detected platform information.
    #>
    Write-Host "`n--- Platform Information ---" -ForegroundColor Yellow

    # Basic platform info
    Write-Host "Type:        " -NoNewline
    Write-Host $script:PlatformInfo.Type -ForegroundColor White
    Write-Host "CPU:         " -NoNewline
    Write-Host $script:PlatformInfo.Details['CPUModel'] -ForegroundColor White
    Write-Host "Architecture:" -NoNewline
    Write-Host $script:PlatformInfo.Details['CpuArchitecture'] -ForegroundColor White
    Write-Host "OS:          " -NoNewline
    Write-Host "$($script:PlatformInfo.Details['OSVersion']) (Build $($script:PlatformInfo.Details['OSBuild']))" -ForegroundColor White

    if ($script:PlatformInfo.Details['Hypervisor']) {
        Write-Host "Hypervisor:  " -NoNewline
        Write-Host $script:PlatformInfo.Details['Hypervisor'] -ForegroundColor White
    }

    # Hardware Security Features
    Write-Host "`n--- Hardware Security Features ---" -ForegroundColor Yellow

    # Firmware Type
    Write-Host "Firmware:    " -NoNewline
    if ($script:HardwareInfo.IsUEFI) {
        Write-Host "UEFI" -ForegroundColor Green
    }
    else {
        Write-Host "Legacy BIOS" -ForegroundColor Yellow
    }

    # Secure Boot
    Write-Host "Secure Boot: " -NoNewline
    if ($script:HardwareInfo.SecureBootEnabled) {
        Write-Host "Enabled" -ForegroundColor Green
    }
    elseif ($script:HardwareInfo.SecureBootCapable) {
        Write-Host "Capable (Disabled)" -ForegroundColor Yellow
    }
    else {
        Write-Host "Not Supported" -ForegroundColor Red
    }

    # TPM
    Write-Host "TPM:         " -NoNewline
    if ($script:HardwareInfo.TPMPresent) {
        Write-Host "Present ($($script:HardwareInfo.TPMVersion))" -ForegroundColor Green
    }
    else {
        Write-Host "Not Detected" -ForegroundColor Red
    }

    # CPU Virtualization
    Write-Host "VT-x/AMD-V:  " -NoNewline
    if ($script:HardwareInfo.VTxEnabled) {
        Write-Host "Enabled" -ForegroundColor Green
    }
    else {
        Write-Host "Disabled or Not Supported" -ForegroundColor Red
    }

    # IOMMU/VT-d
    Write-Host "IOMMU/VT-d:  " -NoNewline
    if ($script:HardwareInfo.IOMMUSupport) {
        Write-Host "Detected" -ForegroundColor Green
    }
    else {
        Write-Host "Not Detected" -ForegroundColor Red
    }

    # VBS Capability
    Write-Host "VBS Capable: " -NoNewline
    if ($script:HardwareInfo.VBSCapable) {
        Write-Host "Yes" -ForegroundColor Green
    }
    else {
        Write-Host "No" -ForegroundColor Red
        if (-not $script:HardwareInfo.IsUEFI) {
            Write-Host "             (Requires: UEFI)" -ForegroundColor Gray
        }
        elseif (-not $script:HardwareInfo.SecureBootCapable) {
            Write-Host "             (Requires: Secure Boot)" -ForegroundColor Gray
        }
        elseif (-not $script:HardwareInfo.VTxEnabled) {
            Write-Host "             (Requires: CPU Virtualization)" -ForegroundColor Gray
        }
        elseif (-not $script:HardwareInfo.IOMMUSupport) {
            Write-Host "             (Requires: IOMMU/VT-d)" -ForegroundColor Gray
        }
    }

    # HVCI Capability
    Write-Host "HVCI Capable:" -NoNewline
    if ($script:HardwareInfo.HVCICapable) {
        Write-Host "Yes" -ForegroundColor Green
    }
    else {
        Write-Host "No (Same requirements as VBS)" -ForegroundColor Red
    }
}