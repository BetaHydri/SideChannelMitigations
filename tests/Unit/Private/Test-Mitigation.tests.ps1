BeforeAll {
    $script:moduleName = 'SideChannelMitigations'

    $projectPath = "$PSScriptRoot\..\..\.." | Convert-Path
    $builtModule = Get-ChildItem -Path "$projectPath\output\module\$script:moduleName\*\$script:moduleName.psd1" -ErrorAction SilentlyContinue |
        Sort-Object { [version](Split-Path $_.Directory -Leaf) } |
        Select-Object -Last 1

    if ($builtModule) {
        Import-Module $builtModule.FullName -Force -ErrorAction Stop
    }
}

Describe 'Test-Mitigation' -Skip:(-not $builtModule) {
    Context 'Function existence' {
        It 'Should exist as a private function in the module' {
            InModuleScope $script:moduleName {
                Get-Command -Name 'Test-Mitigation' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When registry value matches expected' {
        It 'Should return Protected status' {
            InModuleScope $script:moduleName {
                Mock -CommandName Get-ItemProperty -MockWith {
                    [PSCustomObject]@{ TestValue = 1 }
                }
                Mock -CommandName Get-RuntimeMitigationStatus -MockWith { 'N/A' }

                $mitigation = @{
                    Id               = 'TEST'
                    Name             = 'Test Mitigation'
                    CVE              = 'CVE-2020-0000'
                    Category         = 'Critical'
                    RegistryPath     = 'HKLM:\SOFTWARE\Test'
                    RegistryName     = 'TestValue'
                    EnabledValue     = 1
                    Impact           = 'Low'
                    Description      = 'Test description'
                    Recommendation   = 'Enable it'
                    RuntimeDetection = 'TestRuntime'
                }

                $result = Test-Mitigation -Mitigation $mitigation
                $result.RegistryStatus | Should -Be 'Enabled'
                $result.Id | Should -Be 'TEST'
            }
        }
    }

    Context 'When registry value does not match' {
        It 'Should return Disabled registry status' {
            InModuleScope $script:moduleName {
                Mock -CommandName Get-ItemProperty -MockWith {
                    [PSCustomObject]@{ TestValue = 0 }
                }
                Mock -CommandName Get-RuntimeMitigationStatus -MockWith { 'N/A' }

                $mitigation = @{
                    Id               = 'TEST'
                    Name             = 'Test Mitigation'
                    CVE              = 'CVE-2020-0000'
                    Category         = 'Critical'
                    RegistryPath     = 'HKLM:\SOFTWARE\Test'
                    RegistryName     = 'TestValue'
                    EnabledValue     = 1
                    Impact           = 'Low'
                    Description      = 'Test description'
                    Recommendation   = 'Enable it'
                    RuntimeDetection = 'TestRuntime'
                }

                $result = Test-Mitigation -Mitigation $mitigation
                $result.RegistryStatus | Should -Be 'Disabled'
            }
        }
    }

    Context 'When registry key does not exist' {
        It 'Should return Not Configured status' {
            InModuleScope $script:moduleName {
                Mock -CommandName Get-ItemProperty -MockWith { throw 'Not found' }
                Mock -CommandName Get-RuntimeMitigationStatus -MockWith { 'N/A' }

                $mitigation = @{
                    Id               = 'TEST'
                    Name             = 'Test Missing'
                    CVE              = 'CVE-2020-0000'
                    Category         = 'Critical'
                    RegistryPath     = 'HKLM:\SOFTWARE\NonExistent'
                    RegistryName     = 'Missing'
                    EnabledValue     = 1
                    Impact           = 'Low'
                    Description      = 'Test'
                    Recommendation   = 'Enable'
                    RuntimeDetection = 'TestRuntime'
                }

                $result = Test-Mitigation -Mitigation $mitigation
                $result.RegistryStatus | Should -Be 'Not Configured'
            }
        }
    }

    Context 'When mitigation is a prerequisite' {
        It 'Should delegate to Test-Prerequisite' {
            InModuleScope $script:moduleName {
                Mock -CommandName Test-Prerequisite -MockWith {
                    [PSCustomObject]@{
                        Id            = 'PREREQ'
                        Name          = 'Test Prereq'
                        OverallStatus = 'Active'
                    }
                }

                $mitigation = @{
                    Id             = 'PREREQ'
                    Name           = 'Test Prereq'
                    IsPrerequisite = $true
                }

                $result = Test-Mitigation -Mitigation $mitigation
                $result.Id | Should -Be 'PREREQ'
                Should -Invoke -CommandName Test-Prerequisite -Times 1
            }
        }
    }

    Context 'When hardware is not supported' {
        It 'Should return Not Applicable status' {
            InModuleScope $script:moduleName {
                Mock -CommandName Test-HardwareCapability -MockWith { $false }

                $mitigation = @{
                    Id               = 'HWTEST'
                    Name             = 'HW Required'
                    CVE              = 'CVE-2020-0000'
                    Category         = 'Recommended'
                    RegistryPath     = 'HKLM:\SOFTWARE\Test'
                    RegistryName     = 'Val'
                    EnabledValue     = 1
                    Impact           = 'Low'
                    Description      = 'Needs hardware'
                    Recommendation   = 'Upgrade'
                    HardwareRequired = 'VBS'
                }

                $result = Test-Mitigation -Mitigation $mitigation
                $result.OverallStatus | Should -Be 'Not Applicable'
                $result.ActionNeeded | Should -Be 'No'
            }
        }
    }
}
