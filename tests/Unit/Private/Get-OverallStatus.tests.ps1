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

Describe 'Get-OverallStatus' {
    Context 'Runtime status takes priority' {
        It 'Should return Protected when runtime shows Active' {
            InModuleScope $script:moduleName {
                Get-OverallStatus -RegistryStatus 'Not Configured' -RuntimeStatus 'Active' | Should -Be 'Protected'
            }
        }

        It 'Should return Protected when runtime shows Active (Enhanced IBRS)' {
            InModuleScope $script:moduleName {
                Get-OverallStatus -RegistryStatus 'Disabled' -RuntimeStatus 'Active (Enhanced IBRS)' | Should -Be 'Protected'
            }
        }

        It 'Should return Protected when runtime shows Not Needed (HW Immune)' {
            InModuleScope $script:moduleName {
                Get-OverallStatus -RegistryStatus 'Not Configured' -RuntimeStatus 'Not Needed (HW Immune)' | Should -Be 'Protected'
            }
        }

        It 'Should return Vulnerable when runtime shows Inactive' {
            InModuleScope $script:moduleName {
                Get-OverallStatus -RegistryStatus 'Enabled' -RuntimeStatus 'Inactive' | Should -Be 'Vulnerable'
            }
        }

        It 'Should return Vulnerable when runtime shows Inactive (Microcode Update Required)' {
            InModuleScope $script:moduleName {
                Get-OverallStatus -RegistryStatus 'Enabled' -RuntimeStatus 'Inactive (Microcode Update Required)' | Should -Be 'Vulnerable'
            }
        }
    }

    Context 'Fallback to registry when runtime is N/A' {
        It 'Should return Protected when registry shows Enabled' {
            InModuleScope $script:moduleName {
                Get-OverallStatus -RegistryStatus 'Enabled' -RuntimeStatus 'N/A' | Should -Be 'Protected'
            }
        }

        It 'Should return Vulnerable when registry shows Disabled' {
            InModuleScope $script:moduleName {
                Get-OverallStatus -RegistryStatus 'Disabled' -RuntimeStatus 'N/A' | Should -Be 'Vulnerable'
            }
        }

        It 'Should return Vulnerable when registry shows Not Configured' {
            InModuleScope $script:moduleName {
                Get-OverallStatus -RegistryStatus 'Not Configured' -RuntimeStatus 'N/A' | Should -Be 'Vulnerable'
            }
        }
    }
}