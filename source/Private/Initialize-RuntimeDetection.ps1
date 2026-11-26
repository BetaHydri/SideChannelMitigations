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
                # Class 201 returns two DWORDs: Flags and Flags2 (decoded per the Microsoft SpeculationControl module)
                $flags = [System.Runtime.InteropServices.Marshal]::ReadInt32($infoPtr, 0)
                $flags2 = 0
                if ($returnLength -gt 4) {
                    $flags2 = [System.Runtime.InteropServices.Marshal]::ReadInt32($infoPtr, 4)
                }

                # Kernel VA shadow and L1D flush state come from class 196 (SystemKernelVaShadowInformation)
                $kvaFlags = 0
                $hasKvaFlags = $false
                $kvaReturnLength = 0
                $kvaResult = $ntApiType::NtQuerySystemInformation(196, $infoPtr, 4, [ref]$kvaReturnLength)
                if ($kvaResult -eq 0) {
                    $kvaFlags = [System.Runtime.InteropServices.Marshal]::ReadInt32($infoPtr, 0)
                    $hasKvaFlags = $true
                }

                $vendor = ''
                $isArm = $false
                try {
                    $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
                    $vendor = [string]$cpu.Manufacturer
                    $isArm = ($cpu.Architecture -eq 5) -or ($cpu.Architecture -eq 12)
                }
                catch {
                    Write-Debug "CPU vendor detection failed: $($_.Exception.Message)"
                }

                $decoded = ConvertFrom-SpeculationControlFlag -Flags $flags -Flags2 $flags2 -KvaFlags $kvaFlags -HasKvaFlags $hasKvaFlags -CpuVendor $vendor -IsArm $isArm
                foreach ($key in $decoded.Keys) {
                    $script:RuntimeState.Flags[$key] = $decoded[$key]
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