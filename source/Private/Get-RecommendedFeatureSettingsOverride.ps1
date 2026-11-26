function Get-RecommendedFeatureSettingsOverride {
    <#
    .SYNOPSIS
        Calculates the recommended FeatureSettingsOverride value for the current CPU.

    .DESCRIPTION
        Builds the value according to Microsoft KB4072698:
          0x48     (72)   = TAA, MDS, Spectre, Meltdown, MMIO, SSBD and L1TF mitigations with Hyper-Threading enabled
          0x2048   (8264) = same mitigations, variant for systems with Hyper-Threading disabled
          0x800000        = Branch History Injection (CVE-2022-0001), Intel only, combined by bitwise OR
        Without explicit parameters the CPU vendor and Hyper-Threading state are detected once
        and cached for the module session.

    .PARAMETER CpuVendor
        CPU manufacturer string (for example GenuineIntel or AuthenticAMD).

    .PARAMETER HyperThreadingEnabled
        Whether Hyper-Threading/SMT is active on the system.

    .EXAMPLE
        Get-RecommendedFeatureSettingsOverride -CpuVendor 'GenuineIntel' -HyperThreadingEnabled $true

        Returns 8388680 (0x800048).
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [string]$CpuVendor,

        [bool]$HyperThreadingEnabled
    )

    if (-not $PSBoundParameters.ContainsKey('CpuVendor') -or -not $PSBoundParameters.ContainsKey('HyperThreadingEnabled')) {
        if (-not $script:CpuTopologyCache) {
            $vendor = ''
            $htEnabled = $true
            try {
                $cpus = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)
                $vendor = [string]$cpus[0].Manufacturer
                $cores = ($cpus | Measure-Object -Property NumberOfCores -Sum).Sum
                $logical = ($cpus | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
                if ($cores -gt 0 -and $logical -gt 0) {
                    $htEnabled = $logical -gt $cores
                }
            }
            catch {
                Write-Debug "CPU topology detection failed, assuming Hyper-Threading enabled: $($_.Exception.Message)"
            }
            $script:CpuTopologyCache = @{ Vendor = $vendor; HyperThreadingEnabled = $htEnabled }
        }
        $CpuVendor = $script:CpuTopologyCache.Vendor
        $HyperThreadingEnabled = $script:CpuTopologyCache.HyperThreadingEnabled
    }

    $value = 0x48
    if (-not $HyperThreadingEnabled) { $value = $value -bor 0x2000 }
    if ($CpuVendor -match 'Intel') { $value = $value -bor 0x800000 }

    return [int]$value
}
