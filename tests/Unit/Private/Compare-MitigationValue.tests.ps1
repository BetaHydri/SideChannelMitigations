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

Describe 'Compare-MitigationValue' {
    Context 'Standard registry value comparison' {
        It 'Should return true when current equals expected' {
            InModuleScope $script:moduleName {
                Compare-MitigationValue -Current 1 -Expected 1 -RegistryName 'TestReg' | Should -BeTrue
            }
        }

        It 'Should return false when current differs from expected' {
            InModuleScope $script:moduleName {
                Compare-MitigationValue -Current 0 -Expected 1 -RegistryName 'TestReg' | Should -BeFalse
            }
        }

        It 'Should return false when current is null' {
            InModuleScope $script:moduleName {
                Compare-MitigationValue -Current $null -Expected 1 -RegistryName 'TestReg' | Should -BeFalse
            }
        }
    }

    Context 'FeatureSettingsOverride special handling' {
        It 'Should accept 0x2048 (basic mitigations) as enabled' {
            InModuleScope $script:moduleName {
                Compare-MitigationValue -Current 0x2048 -Expected 0x802048 -RegistryName 'FeatureSettingsOverride' | Should -BeTrue
            }
        }

        It 'Should accept 0x802048 (basic+BHI) as enabled' {
            InModuleScope $script:moduleName {
                Compare-MitigationValue -Current 0x802048 -Expected 0x802048 -RegistryName 'FeatureSettingsOverride' | Should -BeTrue
            }
        }

        It 'Should accept 0x800000 (BHI only) as enabled' {
            InModuleScope $script:moduleName {
                Compare-MitigationValue -Current 0x800000 -Expected 0x802048 -RegistryName 'FeatureSettingsOverride' | Should -BeTrue
            }
        }

        It 'Should reject value 0 for FeatureSettingsOverride' {
            InModuleScope $script:moduleName {
                Compare-MitigationValue -Current 0 -Expected 0x802048 -RegistryName 'FeatureSettingsOverride' | Should -BeFalse
            }
        }

        It 'Should reject null for FeatureSettingsOverride' {
            InModuleScope $script:moduleName {
                Compare-MitigationValue -Current $null -Expected 0x802048 -RegistryName 'FeatureSettingsOverride' | Should -BeFalse
            }
        }
    }

    Context 'REG_BINARY byte array handling' {
        It 'Should convert 8-byte array to uint64 and compare' {
            InModuleScope $script:moduleName {
                $bytes = [BitConverter]::GetBytes([uint64]0x2000000000000000)
                Compare-MitigationValue -Current $bytes -Expected ([uint64]0x2000000000000000) -RegistryName 'MitigationOptions' | Should -BeTrue
            }
        }

        It 'Should convert 4-byte array to uint32 and compare' {
            InModuleScope $script:moduleName {
                $bytes = [BitConverter]::GetBytes([uint32]1)
                Compare-MitigationValue -Current $bytes -Expected 1 -RegistryName 'SomeReg' | Should -BeTrue
            }
        }
    }
}