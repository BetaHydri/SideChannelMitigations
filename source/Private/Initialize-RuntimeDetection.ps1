function Initialize-RuntimeDetection {
    <#
    .SYNOPSIS
        Detects real-time kernel mitigation state via Windows API.

    .DESCRIPTION
        Uses NtQuerySystemInformation to query the kernel speculation control flags and populate the runtime mitigation state.

    .EXAMPLE
        Initialize-RuntimeDetection

        Queries kernel for active mitigation flags.
    #>

    Write-Log "Initializing kernel runtime state detection..." -Level Debug

    try {
        # Check if type already exists
        $ntApiType = 'Kernel32.NtApi' -as [type]

        if (-not $ntApiType) {
            # P/Invoke setup for NtQuerySystemInformation
            $signature = @'
[DllImport("ntdll.dll", SetLastError = true)]
public static extern int NtQuerySystemInformation(
    uint SystemInformationClass,
    IntPtr SystemInformation,
    uint SystemInformationLength,
    out uint ReturnLength);
'@
            Add-Type -MemberDefinition $signature -Name 'NtApi' -Namespace 'Kernel32'
            $ntApiType = 'Kernel32.NtApi' -as [type]
        }

        # Query system information (class 201 = SystemSpeculationControlInformation)
        $infoSize = 256
        $infoPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($infoSize)

        try {
            $returnLength = 0
            $result = $ntApiType::NtQuerySystemInformation(
                201,  # SystemSpeculationControlInformation
                $infoPtr,
                $infoSize,
                [ref]$returnLength
            )

            if ($result -eq 0) {
                # Parse the returned structure (8 bytes: flags + flags2)
                # Flag definitions aligned with Microsoft SpeculationControl module
                $flags = [System.Runtime.InteropServices.Marshal]::ReadInt32($infoPtr, 0)

                # Extract individual mitigation states from flags (first DWORD)
                # Based on Microsoft's scf* constants in SpeculationControl.psm1
                $script:RuntimeState.Flags['KVAShadowRequired'] = ($flags -band 0x01) -ne 0
                $script:RuntimeState.Flags['KVAShadowEnabled'] = ($flags -band 0x02) -ne 0
                $script:RuntimeState.Flags['KVAShadowPCIDEnabled'] = ($flags -band 0x04) -ne 0
                $script:RuntimeState.Flags['RDCLHardwareProtected'] = ($flags -band 0x08) -ne 0  # Meltdown hardware immunity
                $script:RuntimeState.Flags['BTIEnabled'] = ($flags -band 0x10) -ne 0
                $script:RuntimeState.Flags['SSBDSystemWide'] = ($flags -band 0x400) -ne 0
                $script:RuntimeState.Flags['RetpolineEnabled'] = ($flags -band 0x4000) -ne 0
                $script:RuntimeState.Flags['EnhancedIBRS'] = ($flags -band 0x10000) -ne 0
                $script:RuntimeState.Flags['MDSHardwareProtected'] = ($flags -band 0x1000000) -ne 0
                $script:RuntimeState.Flags['MBClearEnabled'] = ($flags -band 0x2000000) -ne 0
                $script:RuntimeState.Flags['L1DFlushSupported'] = ($flags -band 0x8000000) -ne 0

                # Read flags2 (second DWORD at offset 4) for newer mitigations
                if ($returnLength -gt 4) {
                    $flags2 = [System.Runtime.InteropServices.Marshal]::ReadInt32($infoPtr, 4)

                    # Extract hardware protection flags (aligned with Microsoft SpeculationControl module)
                    $script:RuntimeState.Flags['SBDRHardwareProtected'] = ($flags2 -band 0x01) -ne 0
                    $script:RuntimeState.Flags['FBSDPHardwareProtected'] = ($flags2 -band 0x02) -ne 0
                    $script:RuntimeState.Flags['PSDPHardwareProtected'] = ($flags2 -band 0x04) -ne 0
                    $script:RuntimeState.Flags['FBClearEnabled'] = ($flags2 -band 0x08) -ne 0
                    $script:RuntimeState.Flags['FBClearReported'] = ($flags2 -band 0x10) -ne 0

                    # AMD and ARM CPUs are hardware immune to these Intel vulnerabilities
                    try {
                        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
                        $isAmdOrArm = ($cpu.Manufacturer -like '*AMD*') -or ($cpu.Architecture -eq 5) -or ($cpu.Architecture -eq 12)

                        if ($isAmdOrArm) {
                            $script:RuntimeState.Flags['SBDRHardwareProtected'] = $true
                            $script:RuntimeState.Flags['FBSDPHardwareProtected'] = $true
                            $script:RuntimeState.Flags['PSDPHardwareProtected'] = $true
                        }
                    }
                    catch {
                        Write-Debug "CPU vendor detection failed: $($_.Exception.Message)"
                    }
                }

                $script:RuntimeState.APIAvailable = $true
                Write-Log "Kernel runtime state detection: Operational" -Level Success
            }
            else {
                Write-Log "NtQuerySystemInformation returned error: 0x$($result.ToString('X8'))" -Level Warning
            }
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($infoPtr)
        }

    }
    catch {
        Write-Log "Kernel runtime detection not available: $($_.Exception.Message)" -Level Warning
        $script:RuntimeState.APIAvailable = $false
    }
}