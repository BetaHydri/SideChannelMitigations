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

Describe 'Set-MitigationValue' -Skip:(-not $builtModule) {
    Context 'Function existence' {
        It 'Should exist as a private function in the module' {
            InModuleScope $script:moduleName {
                Get-Command -Name 'Set-MitigationValue' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When mitigation has no registry path (hardware-only)' {
        It 'Should skip and return null' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'setmit.log'
                Mock -CommandName Write-Host

                $mitigation = @{
                    Name         = 'UEFI Firmware'
                    RegistryPath = ''
                    RegistryName = ''
                    EnabledValue = 1
                }

                $result = Set-MitigationValue -Mitigation $mitigation
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When WhatIf is active' {
        It 'Should return true without setting registry' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'setmit.log'
                Mock -CommandName Write-Host
                Mock -CommandName Set-ItemProperty

                $mitigation = @{
                    Name         = 'Test Mitigation'
                    RegistryPath = 'HKLM:\SOFTWARE\Test'
                    RegistryName = 'TestVal'
                    EnabledValue = 1
                }

                $WhatIfPreference = $true
                $result = Set-MitigationValue -Mitigation $mitigation
                $result | Should -BeTrue
                Should -Invoke -CommandName Set-ItemProperty -Times 0
            }
        }
    }

    Context 'When applying a registry value' {
        It 'Should call Set-ItemProperty and return true' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'setmit.log'
                Mock -CommandName Write-Host
                Mock -CommandName Test-Path -MockWith { $true }
                Mock -CommandName Set-ItemProperty

                $mitigation = @{
                    Name         = 'Test Apply'
                    RegistryPath = 'HKLM:\SOFTWARE\Test'
                    RegistryName = 'ApplyVal'
                    EnabledValue = 1
                }

                $WhatIfPreference = $false
                $result = Set-MitigationValue -Mitigation $mitigation
                $result | Should -BeTrue
                Should -Invoke -CommandName Set-ItemProperty -Times 1
            }
        }

        It 'Should create registry path if it does not exist' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'setmit.log'
                Mock -CommandName Write-Host
                Mock -CommandName Test-Path -MockWith { $false }
                Mock -CommandName New-Item -MockWith { $null }
                Mock -CommandName Set-ItemProperty

                $mitigation = @{
                    Name         = 'New Path'
                    RegistryPath = 'HKLM:\SOFTWARE\NewPath'
                    RegistryName = 'Val'
                    EnabledValue = 1
                }

                $WhatIfPreference = $false
                Set-MitigationValue -Mitigation $mitigation
                Should -Invoke -CommandName New-Item -Times 1
            }
        }
    }

    Context 'When Set-ItemProperty fails' {
        It 'Should return false on error' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'setmit.log'
                Mock -CommandName Write-Host
                Mock -CommandName Test-Path -MockWith { $true }
                Mock -CommandName Set-ItemProperty -MockWith { throw 'Access denied' }

                $mitigation = @{
                    Name         = 'Fail Test'
                    RegistryPath = 'HKLM:\SOFTWARE\Test'
                    RegistryName = 'FailVal'
                    EnabledValue = 1
                }

                $WhatIfPreference = $false
                $result = Set-MitigationValue -Mitigation $mitigation
                $result | Should -BeFalse
            }
        }
    }
}
