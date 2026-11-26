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

Describe 'Get-RecommendedFeatureSettingsOverride' {
    It 'Should return 72 for AMD with Hyper-Threading enabled' {
        InModuleScope $script:moduleName {
            Get-RecommendedFeatureSettingsOverride -CpuVendor 'AuthenticAMD' -HyperThreadingEnabled $true | Should -Be 72
        }
    }

    It 'Should return 8264 for AMD with Hyper-Threading disabled' {
        InModuleScope $script:moduleName {
            Get-RecommendedFeatureSettingsOverride -CpuVendor 'AuthenticAMD' -HyperThreadingEnabled $false | Should -Be 8264
        }
    }

    It 'Should add BHI for Intel with Hyper-Threading enabled' {
        InModuleScope $script:moduleName {
            Get-RecommendedFeatureSettingsOverride -CpuVendor 'GenuineIntel' -HyperThreadingEnabled $true | Should -Be 0x800048
        }
    }

    It 'Should add BHI for Intel with Hyper-Threading disabled' {
        InModuleScope $script:moduleName {
            Get-RecommendedFeatureSettingsOverride -CpuVendor 'GenuineIntel' -HyperThreadingEnabled $false | Should -Be 0x802048
        }
    }

    Context 'Detection' {
        BeforeEach {
            InModuleScope $script:moduleName { $script:CpuTopologyCache = $null }
        }

        AfterEach {
            InModuleScope $script:moduleName { $script:CpuTopologyCache = $null }
        }

        It 'Should detect Hyper-Threading from logical vs physical core count' {
            InModuleScope $script:moduleName {
                Mock Get-CimInstance {
                    [PSCustomObject]@{ Manufacturer = 'GenuineIntel'; NumberOfCores = 4; NumberOfLogicalProcessors = 8 }
                }
                Get-RecommendedFeatureSettingsOverride | Should -Be 0x800048
            }
        }

        It 'Should detect disabled Hyper-Threading' {
            InModuleScope $script:moduleName {
                Mock Get-CimInstance {
                    [PSCustomObject]@{ Manufacturer = 'AuthenticAMD'; NumberOfCores = 4; NumberOfLogicalProcessors = 4 }
                }
                Get-RecommendedFeatureSettingsOverride | Should -Be 8264
            }
        }

        It 'Should fall back to Hyper-Threading enabled when detection fails' {
            InModuleScope $script:moduleName {
                Mock Get-CimInstance { throw 'CIM unavailable' }
                Get-RecommendedFeatureSettingsOverride | Should -Be 72
            }
        }
    }
}
