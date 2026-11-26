function ConvertFrom-SpeculationControlFlag {
    <#
    .SYNOPSIS
        Decodes the kernel speculation control flags into named mitigation state flags.

    .DESCRIPTION
        Decodes the values returned by NtQuerySystemInformation using the bit definitions of the
        Microsoft SpeculationControl module:
          Class 201 (SystemSpeculationControlInformation): Flags and Flags2
          Class 196 (SystemKernelVaShadowInformation): kernel VA shadow and L1D flush flags
        Kernel VA shadow state is only available from class 196, it is not part of class 201.

    .PARAMETER Flags
        First DWORD of the class 201 result.

    .PARAMETER Flags2
        Second DWORD of the class 201 result (0 when the kernel returns only one DWORD).

    .PARAMETER KvaFlags
        DWORD of the class 196 result.

    .PARAMETER HasKvaFlags
        Whether the class 196 query succeeded.

    .PARAMETER CpuVendor
        CPU manufacturer string.

    .PARAMETER IsArm
        Whether the CPU is an ARM architecture.

    .EXAMPLE
        ConvertFrom-SpeculationControlFlag -Flags 0x1 -Flags2 0 -KvaFlags 0x20 -HasKvaFlags $true -CpuVendor 'GenuineIntel'

        Returns the decoded flag table.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [long]$Flags,

        [long]$Flags2 = 0,

        [long]$KvaFlags = 0,

        [bool]$HasKvaFlags = $false,

        [string]$CpuVendor = '',

        [bool]$IsArm = $false
    )

    $isAmdOrArm = ($CpuVendor -like '*AMD*') -or $IsArm

    $ssbdAvailable = ($Flags -band 0x100) -ne 0
    $rdclReported = ($Flags2 -band 0x800) -ne 0

    $result = @{
        # Class 201, Flags
        BTIEnabled                   = ($Flags -band 0x01) -ne 0
        BTIDisabledSystemPolicy      = ($Flags -band 0x02) -ne 0
        BTIDisabledNoHardwareSupport = ($Flags -band 0x04) -ne 0
        SSBDAvailable                = $ssbdAvailable
        SSBDSystemWide               = $ssbdAvailable -and (($Flags -band 0x400) -ne 0)
        RetpolineEnabled             = ($Flags -band 0x4000) -ne 0
        EnhancedIBRS                 = ($Flags -band 0x10000) -ne 0
        MDSHardwareProtected         = $isAmdOrArm -or (($Flags -band 0x1000000) -ne 0)
        MBClearEnabled               = ($Flags -band 0x2000000) -ne 0

        # Class 201, Flags2
        SBDRHardwareProtected        = $isAmdOrArm -or (($Flags2 -band 0x01) -ne 0)
        FBSDPHardwareProtected       = $isAmdOrArm -or (($Flags2 -band 0x02) -ne 0)
        PSDPHardwareProtected        = $isAmdOrArm -or (($Flags2 -band 0x04) -ne 0)
        FBClearEnabled               = ($Flags2 -band 0x08) -ne 0
        FBClearReported              = ($Flags2 -band 0x10) -ne 0
        RDCLHardwareProtected        = $rdclReported -and (($Flags2 -band 0x1000) -ne 0)

        # Class 196
        KVAShadowEnabled             = $false
        KVAShadowRequired            = $null
        L1DFlushSupported            = $false
    }

    if ($HasKvaFlags) {
        $result.KVAShadowEnabled = ($KvaFlags -band 0x01) -ne 0
        $result.L1DFlushSupported = ($KvaFlags -band 0x1000) -ne 0

        if (($KvaFlags -band 0x20) -ne 0) {
            $result.KVAShadowRequired = ($KvaFlags -band 0x10) -ne 0
        }
        elseif ($isAmdOrArm) {
            $result.KVAShadowRequired = $false
        }
        else {
            $result.KVAShadowRequired = $true
        }
    }

    return $result
}
