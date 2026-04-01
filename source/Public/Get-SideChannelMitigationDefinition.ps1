function Get-SideChannelMitigationDefinition {
    <#
    .SYNOPSIS
        Returns the side-channel mitigation definitions.

    .DESCRIPTION
        Returns an array of mitigation definition hashtables containing registry paths, expected values, and metadata for all known side-channel vulnerabilities.

    .EXAMPLE
        Get-SideChannelMitigationDefinition

        Returns all mitigation definitions.
    #>

    return @(
        # Critical - Spectre/Meltdown core mitigations
        @{
            Id               = 'SSBD'
            Name             = 'Speculative Store Bypass Disable'
            CVE              = 'CVE-2018-3639'
            Category         = 'Critical'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
            RegistryName     = 'FeatureSettingsOverride'
            EnabledValue     = 0x802048  # Microsoft KB4072698: 0x2048 (8264) = Basic only, 0x802048 (8396872) = Basic+BHI (RECOMMENDED for Intel)
            Description      = 'Prevents Speculative Store Bypass (Variant 4) attacks'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = 'SSBD'
            Recommendation   = 'Intel CPUs: Set to 0x802048 (8396872) for Basic+BHI mitigations. AMD CPUs: Set to 0x2048 (8264) for Basic mitigations. Use bitwise OR (0x2048 | 0x800000 = 0x802048) to combine. Value 0 does NOT enable system-wide.'
            URL              = 'https://support.microsoft.com/en-us/topic/kb4072698-windows-server-and-azure-stack-hci-guidance-to-protect-against-silicon-based-microarchitectural-and-speculative-execution-side-channel-vulnerabilities-2f965763-00e2-8f98-b632-0d96f30c8c8e'
        },
        @{
            Id               = 'SSBD_Mask'
            Name             = 'SSBD Feature Mask'
            CVE              = 'CVE-2018-3639'
            Category         = 'Critical'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
            RegistryName     = 'FeatureSettingsOverrideMask'
            EnabledValue     = 3
            Description      = 'Required companion setting for SSBD'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Must be enabled for SSBD to function'
            URL              = 'https://nvd.nist.gov/vuln/detail/CVE-2018-3639'
        },
        @{
            Id               = 'BTI'
            Name             = 'Branch Target Injection Mitigation'
            CVE              = 'CVE-2017-5715 (Spectre v2)'
            Category         = 'Critical'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'DisablePageCombining'
            EnabledValue     = 0
            Description      = 'Mitigates Spectre Variant 2 attacks'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = 'BTI'
            Recommendation   = 'Essential protection against Spectre v2'
            URL              = 'https://nvd.nist.gov/vuln/detail/CVE-2017-5715'
        },
        @{
            Id               = 'KVAS'
            Name             = 'Kernel VA Shadow (Meltdown Protection)'
            CVE              = 'CVE-2017-5754 (Meltdown)'
            Category         = 'Critical'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
            RegistryName     = 'EnableKernelVaShadow'
            EnabledValue     = 1
            Description      = 'Page table isolation to prevent Meltdown attacks'
            Impact           = 'Medium'
            Platform         = 'All'
            RuntimeDetection = 'KVAS'
            Recommendation   = 'Critical for Meltdown protection; modern CPUs have hardware immunity'
            URL              = 'https://nvd.nist.gov/vuln/detail/CVE-2017-5754'
        },
        @{
            Id               = 'EnhancedIBRS'
            Name             = 'Enhanced IBRS'
            CVE              = 'CVE-2017-5715 (Spectre v2)'
            Category         = 'Critical'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'IbrsEnabled'
            EnabledValue     = 1
            Description      = 'Hardware-based Spectre v2 protection'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable on CPUs with Enhanced IBRS support'
            URL              = 'https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/technical-documentation/indirect-branch-restricted-speculation.html'
        },
        @{
            Id               = 'TSXDisable'
            Name             = 'Intel TSX Disable'
            CVE              = 'CVE-2019-11135 (TAA)'
            Category         = 'Recommended'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'DisableTsx'
            EnabledValue     = 1
            Description      = 'Disable Intel TSX to prevent TAA vulnerabilities'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Disable unless specifically required by applications'
            URL              = 'https://nvd.nist.gov/vuln/detail/CVE-2019-11135'
        },

        # High-impact mitigations
        @{
            Id               = 'L1TF'
            Name             = 'L1 Terminal Fault Mitigation'
            CVE              = 'CVE-2018-3620 (Foreshadow)'
            Category         = 'Optional'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'L1TFMitigationLevel'
            EnabledValue     = 1
            Description      = 'Protects against L1 Terminal Fault (Foreshadow)'
            Impact           = 'High'
            Platform         = 'HyperVHost'
            RuntimeDetection = 'L1TF'
            Recommendation   = 'High performance impact; for multi-tenant virtualization only'
            URL              = 'https://nvd.nist.gov/vuln/detail/CVE-2018-3620'
        },
        @{
            Id               = 'MDS'
            Name             = 'MDS Mitigation (ZombieLoad)'
            CVE              = 'CVE-2018-12130 (ZombieLoad)'
            Category         = 'Recommended'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'MDSMitigationLevel'
            EnabledValue     = 1
            Description      = 'Protects against MDS attacks'
            Impact           = 'Medium'
            Platform         = 'All'
            RuntimeDetection = 'MDS'
            Recommendation   = 'Moderate performance impact; modern CPUs have hardware immunity'
            URL              = 'https://nvd.nist.gov/vuln/detail/CVE-2018-12130'
        },
        @{
            Id               = 'TAA'
            Name             = 'TSX Asynchronous Abort Mitigation'
            CVE              = 'CVE-2019-11135 (TAA)'
            Category         = 'Recommended'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'TSXAsyncAbortLevel'
            EnabledValue     = 1
            Description      = 'Protects against TAA vulnerabilities'
            Impact           = 'Medium'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable if TSX cannot be disabled'
            URL              = 'https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/technical-documentation/intel-tsx-asynchronous-abort.html'
        },
        @{
            Id               = 'HWMitigations'
            Name             = 'Hardware Security Mitigations'
            CVE              = 'Multiple'
            Category         = 'Critical'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'MitigationOptions'
            EnabledValue     = 0x2000000000000000
            Description      = 'Core hardware-based security features (requires CPU support)'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable core hardware mitigation features (Note: VMs require CPU features exposed by hypervisor - see VM configuration guidance for Hyper-V/VMware)'
        },

        # Additional Side-Channel Mitigations (2022+)
        @{
            Id               = 'SBDR'
            Name             = 'SBDR/SBDS Mitigation'
            CVE              = 'CVE-2022-21123, CVE-2022-21125'
            Category         = 'Critical'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'SBDRMitigationLevel'
            EnabledValue     = 1
            Description      = 'Shared Buffer Data Read/Sampling protection'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = 'SBDR'
            Recommendation   = 'Enable to protect against SBDR/SBDS attacks (VM Note: Hypervisor host must have this mitigation enabled and restarted first - see HYPERVISOR_CONFIGURATION.md)'
            URL              = 'https://nvd.nist.gov/vuln/detail/CVE-2022-21123'
        },
        @{
            Id               = 'FBSDP'
            Name             = 'FBSDP Mitigation'
            CVE              = 'CVE-2022-21123 (Fill Buffer Variant)'
            Category         = 'Recommended'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'SBDRMitigationLevel'
            EnabledValue     = 1
            Description      = 'Fill Buffer Stale Data Propagator protection'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = 'FBSDP'
            Recommendation   = 'Enable to protect against FBSDP attacks (VM Note: Hypervisor host must have this mitigation enabled and restarted first - see HYPERVISOR_CONFIGURATION.md)'
            URL              = 'https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/technical-documentation/processor-mmio-stale-data-vulnerabilities.html'
        },
        @{
            Id               = 'SRBDS'
            Name             = 'SRBDS Update Mitigation'
            CVE              = 'CVE-2022-21127'
            Category         = 'Recommended'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'SRBDSMitigationLevel'
            EnabledValue     = 1
            Description      = 'Special Register Buffer Data Sampling protection'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable to protect against SRBDS attacks (VM Note: Hypervisor host must have this mitigation enabled and restarted first - see HYPERVISOR_CONFIGURATION.md)'
            URL              = 'https://nvd.nist.gov/vuln/detail/CVE-2022-21127'
        },
        @{
            Id               = 'DRPW'
            Name             = 'DRPW Mitigation'
            CVE              = 'CVE-2022-21166'
            Category         = 'Recommended'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'DRPWMitigationLevel'
            EnabledValue     = 1
            Description      = 'Device Register Partial Write protection'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable to protect against DRPW attacks (VM Note: Hypervisor host must have this mitigation enabled and restarted first - see HYPERVISOR_CONFIGURATION.md)'
            URL              = 'https://nvd.nist.gov/vuln/detail/CVE-2022-21166'
        },
        @{
            Id               = 'PSDP'
            Name             = 'Predictive Store Forwarding Disable'
            CVE              = 'CVE-2022-0001, CVE-2022-0002 (Branch History Injection)'
            Category         = 'Critical'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'PredictiveStoreForwardingDisable'
            EnabledValue     = 1
            Description      = 'Prevents Branch History Injection (BHI/Spectre-BHB) attacks'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = 'PSDP'
            Recommendation   = 'Enable to protect against Branch History Injection vulnerabilities (VM Note: Hypervisor host must have this mitigation enabled and restarted first - see HYPERVISOR_CONFIGURATION.md)'
            URL              = 'https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/technical-documentation/branch-history-injection.html'
        },
        @{
            Id               = 'Retbleed'
            Name             = 'Retbleed Mitigation'
            CVE              = 'CVE-2022-29900, CVE-2022-29901'
            Category         = 'Recommended'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'RetpolineConfiguration'
            EnabledValue     = 1
            Description      = 'Mitigates return instruction speculation vulnerability (Retbleed)'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable to protect against Retbleed attacks on AMD and Intel CPUs (VM Note: Hypervisor host must have this mitigation enabled and restarted first - see HYPERVISOR_CONFIGURATION.md)'
            URL              = 'https://www.amd.com/en/corporate/product-security/bulletin/amd-sb-1037'
        },
        @{
            Id               = 'MMIO'
            Name             = 'MMIO Stale Data Mitigation'
            CVE              = 'CVE-2022-21166, CVE-2022-21127 (MMIO variants)'
            Category         = 'Recommended'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'MmioStaleDataMitigationLevel'
            EnabledValue     = 1
            Description      = 'Protects against processor MMIO stale data vulnerabilities'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable to protect against MMIO stale data attacks (VM Note: Hypervisor host must have this mitigation enabled and restarted first - see HYPERVISOR_CONFIGURATION.md)'
            URL              = 'https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/technical-documentation/processor-mmio-stale-data-vulnerabilities.html'
        },

        # Security Features
        @{
            Id               = 'ExceptionChainValidation'
            Name             = 'Exception Chain Validation'
            CVE              = 'General SEH Protection'
            Category         = 'Recommended'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'DisableExceptionChainValidation'
            EnabledValue     = 0
            Description      = 'Validates exception handler chains (SEH protection)'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable to prevent SEH exploitation'
            URL              = 'https://learn.microsoft.com/en-us/windows/win32/secbp/control-flow-guard'
        },
        @{
            Id               = 'SMAP'
            Name             = 'Supervisor Mode Access Prevention'
            CVE              = 'Privilege Escalation Protection'
            Category         = 'Recommended'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
            RegistryName     = 'MoveImages'
            EnabledValue     = 1
            Description      = 'Prevents kernel access to user-mode pages'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable to prevent privilege escalation attacks'
            URL              = 'https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/secure-coding/supervisor-mode-access-prevention.html'
        },
        @{
            Id               = 'VBS'
            Name             = 'Virtualization Based Security'
            CVE              = 'Kernel Isolation'
            Category         = 'Optional'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
            RegistryName     = 'EnableVirtualizationBasedSecurity'
            EnabledValue     = 1
            Description      = 'Hardware-based security isolation using virtualization'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable for enhanced kernel isolation (requires hardware support)'
            HardwareRequired = 'VBS'
            PrerequisiteFor  = 'HVCI, Credential Guard'
            URL              = 'https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-vbs'
        },
        @{
            Id               = 'HVCI'
            Name             = 'Hypervisor-protected Code Integrity'
            CVE              = 'Code Injection Protection'
            Category         = 'Optional'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
            RegistryName     = 'Enabled'
            EnabledValue     = 1
            Description      = 'Hardware-enforced code integrity using hypervisor'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable for kernel code integrity enforcement (requires VBS)'
            HardwareRequired = 'HVCI'
            URL              = 'https://learn.microsoft.com/en-us/windows/security/hardware-security/enable-virtualization-based-protection-of-code-integrity'
        },
        @{
            Id               = 'CredentialGuard'
            Name             = 'Credential Guard'
            CVE              = 'Credential Theft Protection'
            Category         = 'Optional'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
            RegistryName     = 'LsaCfgFlags'
            EnabledValue     = 1
            Description      = 'Protects domain credentials using VBS'
            Impact           = 'Low'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable for domain credential protection (requires VBS)'
            HardwareRequired = 'VBS'
            URL              = 'https://learn.microsoft.com/en-us/windows/security/identity-protection/credential-guard/credential-guard'
        },
        @{
            Id               = 'HyperVCoreScheduler'
            Name             = 'Hyper-V Core Scheduler'
            CVE              = 'SMT Side-Channel Protection'
            Category         = 'Optional'
            RegistryPath     = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization'
            RegistryName     = 'CoreSchedulerType'
            EnabledValue     = 1
            Description      = 'Prevents SMT-based side-channel attacks between VMs'
            Impact           = 'Medium'
            Platform         = 'HyperVHost'
            RuntimeDetection = $null
            Recommendation   = 'Enable on Hyper-V hosts for multi-tenant environments'
            URL              = 'https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/manage-hyper-v-scheduler-types'
        },
        @{
            Id               = 'DisableSMT'
            Name             = 'Disable Simultaneous Multithreading'
            CVE              = 'SMT/Hyperthreading Side-Channel Protection'
            Category         = 'Optional'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
            RegistryName     = 'DisableHyperthreading'
            EnabledValue     = 1
            Description      = 'Disables SMT/Hyperthreading for maximum side-channel protection'
            Impact           = 'Very High'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Only for highest security environments - causes ~50% performance loss. Consider Hyper-V Core Scheduler instead for VMs.'
            URL              = 'https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/manage-hyper-v-scheduler-types'
        },

        # Hardware Prerequisites (Informational)
        @{
            Id               = 'UEFI'
            Name             = 'UEFI Firmware'
            CVE              = 'Boot Security Prerequisite'
            Category         = 'Prerequisite'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State'
            RegistryName     = 'UEFISecureBootEnabled'
            EnabledValue     = $null
            Description      = 'UEFI firmware mode (required for Secure Boot and modern security)'
            Impact           = 'None'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'UEFI mode required for Secure Boot, VBS, and HVCI'
            IsPrerequisite   = $true
            PrerequisiteFor  = 'Secure Boot, VBS, HVCI, Credential Guard'
            URL              = 'https://uefi.org/specifications'
        },
        @{
            Id               = 'SecureBoot'
            Name             = 'Secure Boot'
            CVE              = 'Boot Malware Protection'
            Category         = 'Prerequisite'
            RegistryPath     = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State'
            RegistryName     = 'UEFISecureBootEnabled'
            EnabledValue     = 1
            Description      = 'Prevents unauthorized bootloaders and boot-level malware'
            Impact           = 'None'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable in UEFI firmware settings for boot security'
            IsPrerequisite   = $true
            PrerequisiteFor  = 'VBS, HVCI, Credential Guard'
            URL              = 'https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-secure-boot'
        },
        @{
            Id               = 'TPM'
            Name             = 'TPM 2.0'
            CVE              = 'Hardware Cryptographic Security'
            Category         = 'Prerequisite'
            RegistryPath     = $null
            RegistryName     = $null
            EnabledValue     = $null
            Description      = 'Trusted Platform Module for hardware-based cryptography'
            Impact           = 'None'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'TPM 2.0 required for BitLocker, Credential Guard, and VBS'
            IsPrerequisite   = $true
            PrerequisiteFor  = 'BitLocker, VBS, Credential Guard, Windows Hello'
            URL              = 'https://trustedcomputinggroup.org/resource/tpm-library-specification/'
        },
        @{
            Id               = 'VTx'
            Name             = 'CPU Virtualization (VT-x/AMD-V)'
            CVE              = 'Virtualization Prerequisite'
            Category         = 'Prerequisite'
            RegistryPath     = $null
            RegistryName     = $null
            EnabledValue     = $null
            Description      = 'Hardware virtualization support for Hyper-V and VBS'
            Impact           = 'None'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Enable in BIOS/UEFI for Hyper-V and VBS support'
            IsPrerequisite   = $true
            PrerequisiteFor  = 'Hyper-V, VBS, HVCI, Credential Guard'
            URL              = 'https://www.intel.com/content/www/us/en/virtualization/virtualization-technology/intel-virtualization-technology.html'
        },
        @{
            Id               = 'IOMMU'
            Name             = 'IOMMU/VT-d Support'
            CVE              = 'DMA Protection'
            Category         = 'Prerequisite'
            RegistryPath     = $null
            RegistryName     = $null
            EnabledValue     = $null
            Description      = 'I/O Memory Management Unit for DMA protection'
            Impact           = 'None'
            Platform         = 'All'
            RuntimeDetection = $null
            Recommendation   = 'Required for HVCI and advanced VBS features'
            IsPrerequisite   = $true
            PrerequisiteFor  = 'HVCI, VBS (full isolation), Kernel DMA Protection'
            URL              = 'https://www.intel.com/content/www/us/en/virtualization/virtualization-technology/intel-virtualization-technology-for-directed-io.html'
        }
    )
}