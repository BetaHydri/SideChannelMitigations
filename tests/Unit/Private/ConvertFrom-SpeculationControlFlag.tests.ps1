BeforeAll {
    $script:moduleName = 'SideChannelMitigations'

    $projectPath = "$PSScriptRoot\..\..\.." | Convert-Path
    $builtModule = Get-ChildItem -Path "$projectPath\output\module\$script:moduleName\*\$script:moduleName.psd1" -ErrorAction SilentlyContinue |
        Sort-Object { [version](Split-Path $_.Directory -Leaf) } |
        Select-Object -Last 1

    if ($builtModule) {
        Import-Module $builtModule.FullName -Force -ErrorAction Stop
    }
    else {
        $sourcePath = Join-Path $projectPath 'source'
        Get-ChildItem -Path "$sourcePath\Private\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }
        Get-ChildItem -Path "$sourcePath\Public\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }
    }
}

Describe 'ConvertFrom-SpeculationControlFlag' {
    Context 'Class 201 Flags (bit layout of the Microsoft SpeculationControl module)' {
        It 'Should not read BTI/SpecCtrl bits 0x02, 0x08 and 0x10 as kernel VA shadow or Meltdown immunity' {
            InModuleScope $script:moduleName {
                $f = ConvertFrom-SpeculationControlFlag -Flags 0x1A -CpuVendor 'GenuineIntel'
                $f.KVAShadowEnabled | Should -BeFalse
                $f.RDCLHardwareProtected | Should -BeFalse
                $f.BTIEnabled | Should -BeFalse
                $f.BTIDisabledSystemPolicy | Should -BeTrue
            }
        }

        It 'Should report BTI enabled only for the BpbEnabled bit (0x01)' {
            InModuleScope $script:moduleName {
                (ConvertFrom-SpeculationControlFlag -Flags 0x01).BTIEnabled | Should -BeTrue
                (ConvertFrom-SpeculationControlFlag -Flags 0x04).BTIDisabledNoHardwareSupport | Should -BeTrue
            }
        }

        It 'Should report SSBD system-wide only when SSBD is available' {
            InModuleScope $script:moduleName {
                (ConvertFrom-SpeculationControlFlag -Flags 0x400).SSBDSystemWide | Should -BeFalse
                (ConvertFrom-SpeculationControlFlag -Flags 0x500).SSBDSystemWide | Should -BeTrue
            }
        }

        It 'Should decode Retpoline, Enhanced IBRS and MDS flags' {
            InModuleScope $script:moduleName {
                $f = ConvertFrom-SpeculationControlFlag -Flags (0x4000 -bor 0x10000 -bor 0x1000000 -bor 0x2000000) -CpuVendor 'GenuineIntel'
                $f.RetpolineEnabled | Should -BeTrue
                $f.EnhancedIBRS | Should -BeTrue
                $f.MDSHardwareProtected | Should -BeTrue
                $f.MBClearEnabled | Should -BeTrue
            }
        }
    }

    Context 'Class 201 Flags2' {
        It 'Should report Meltdown hardware immunity only when reported and protected' {
            InModuleScope $script:moduleName {
                (ConvertFrom-SpeculationControlFlag -Flags 0 -Flags2 0x1800).RDCLHardwareProtected | Should -BeTrue
                (ConvertFrom-SpeculationControlFlag -Flags 0 -Flags2 0x1000).RDCLHardwareProtected | Should -BeFalse
                (ConvertFrom-SpeculationControlFlag -Flags 0 -Flags2 0x0800).RDCLHardwareProtected | Should -BeFalse
            }
        }

        It 'Should decode stale data and fill buffer clear flags' {
            InModuleScope $script:moduleName {
                $f = ConvertFrom-SpeculationControlFlag -Flags 0 -Flags2 0x1F -CpuVendor 'GenuineIntel'
                $f.SBDRHardwareProtected | Should -BeTrue
                $f.FBSDPHardwareProtected | Should -BeTrue
                $f.PSDPHardwareProtected | Should -BeTrue
                $f.FBClearEnabled | Should -BeTrue
                $f.FBClearReported | Should -BeTrue
            }
        }

        It 'Should treat AMD and ARM CPUs as hardware immune to the Intel-only issues' {
            InModuleScope $script:moduleName {
                $amd = ConvertFrom-SpeculationControlFlag -Flags 0 -Flags2 0 -CpuVendor 'AuthenticAMD'
                $arm = ConvertFrom-SpeculationControlFlag -Flags 0 -Flags2 0 -IsArm $true
                foreach ($f in $amd, $arm) {
                    $f.SBDRHardwareProtected | Should -BeTrue
                    $f.MDSHardwareProtected | Should -BeTrue
                }
            }
        }
    }

    Context 'Class 196 kernel VA shadow flags' {
        It 'Should read kernel VA shadow enabled and L1D flush support' {
            InModuleScope $script:moduleName {
                $f = ConvertFrom-SpeculationControlFlag -Flags 0 -KvaFlags 0x1001 -HasKvaFlags $true -CpuVendor 'GenuineIntel'
                $f.KVAShadowEnabled | Should -BeTrue
                $f.L1DFlushSupported | Should -BeTrue
            }
        }

        It 'Should use the required flag when the kernel reports it as available' {
            InModuleScope $script:moduleName {
                (ConvertFrom-SpeculationControlFlag -Flags 0 -KvaFlags 0x20 -HasKvaFlags $true -CpuVendor 'GenuineIntel').KVAShadowRequired | Should -BeFalse
                (ConvertFrom-SpeculationControlFlag -Flags 0 -KvaFlags 0x30 -HasKvaFlags $true -CpuVendor 'GenuineIntel').KVAShadowRequired | Should -BeTrue
            }
        }

        It 'Should assume kernel VA shadow is required on Intel and not required on AMD when not reported' {
            InModuleScope $script:moduleName {
                (ConvertFrom-SpeculationControlFlag -Flags 0 -KvaFlags 0 -HasKvaFlags $true -CpuVendor 'GenuineIntel').KVAShadowRequired | Should -BeTrue
                (ConvertFrom-SpeculationControlFlag -Flags 0 -KvaFlags 0 -HasKvaFlags $true -CpuVendor 'AuthenticAMD').KVAShadowRequired | Should -BeFalse
            }
        }

        It 'Should leave kernel VA shadow state unknown when the class 196 query failed' {
            InModuleScope $script:moduleName {
                $f = ConvertFrom-SpeculationControlFlag -Flags 0x1A -HasKvaFlags $false
                $f.KVAShadowRequired | Should -BeNullOrEmpty
                $f.KVAShadowEnabled | Should -BeFalse
            }
        }
    }

    Context 'Runtime status of a Meltdown-immune Hyper-V guest (real Server 2022 output)' {
        It 'Should report KVAS as not needed instead of inactive' {
            InModuleScope $script:moduleName {
                $script:RuntimeState = @{
                    APIAvailable = $true
                    Flags        = ConvertFrom-SpeculationControlFlag -Flags 0x04 -Flags2 0x1807 -KvaFlags 0x20 -HasKvaFlags $true -CpuVendor 'GenuineIntel'
                }
                Get-RuntimeMitigationStatus -MitigationId 'KVAS' | Should -Be 'Not Needed (HW Immune)'
                Get-RuntimeMitigationStatus -MitigationId 'BTI' | Should -Be 'Inactive'
                Get-RuntimeMitigationStatus -MitigationId 'SSBD' | Should -Be 'Inactive'
            }
        }
    }
}
