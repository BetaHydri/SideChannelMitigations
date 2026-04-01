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

Describe 'Restore-Configuration' -Skip:(-not $builtModule) {
    Context 'Function existence' {
        It 'Should exist as a private function in the module' {
            InModuleScope $script:moduleName {
                Get-Command -Name 'Restore-Configuration' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When WhatIf is active' {
        It 'Should preview changes without modifying registry' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'restore.log'
                Mock -CommandName Write-Host
                Mock -CommandName Set-ItemProperty

                $backup = [PSCustomObject]@{
                    Timestamp   = '2026-01-01T10:00:00'
                    Mitigations = @(
                        [PSCustomObject]@{
                            Name         = 'SSBD'
                            RegistryPath = 'HKLM:\SOFTWARE\Test'
                            RegistryName = 'Val'
                            Value        = 1
                        }
                    )
                }

                $WhatIfPreference = $true
                Restore-Configuration -Backup $backup
                Should -Invoke -CommandName Set-ItemProperty -Times 0
            }
        }
    }

    Context 'When restoring registry values' {
        It 'Should call Set-ItemProperty for each restorable item' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'restore.log'
                Mock -CommandName Write-Host
                Mock -CommandName Set-ItemProperty

                $backup = [PSCustomObject]@{
                    Timestamp   = '2026-01-01T10:00:00'
                    Mitigations = @(
                        [PSCustomObject]@{
                            Name         = 'SSBD'
                            RegistryPath = 'HKLM:\SOFTWARE\Test'
                            RegistryName = 'Val1'
                            Value        = 1
                        }
                        [PSCustomObject]@{
                            Name         = 'BTI'
                            RegistryPath = 'HKLM:\SOFTWARE\Test'
                            RegistryName = 'Val2'
                            Value        = 0
                        }
                    )
                }

                $WhatIfPreference = $false
                Restore-Configuration -Backup $backup
                Should -Invoke -CommandName Set-ItemProperty -Times 2
            }
        }
    }

    Context 'When backup contains hardware-only items' {
        It 'Should skip items with empty registry path' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'restore.log'
                Mock -CommandName Write-Host
                Mock -CommandName Set-ItemProperty

                $backup = [PSCustomObject]@{
                    Timestamp   = '2026-01-01T10:00:00'
                    Mitigations = @(
                        [PSCustomObject]@{
                            Name         = 'UEFI'
                            RegistryPath = ''
                            RegistryName = ''
                            Value        = $null
                        }
                        [PSCustomObject]@{
                            Name         = 'SSBD'
                            RegistryPath = 'HKLM:\SOFTWARE\Test'
                            RegistryName = 'Val'
                            Value        = 1
                        }
                    )
                }

                $WhatIfPreference = $false
                Restore-Configuration -Backup $backup
                Should -Invoke -CommandName Set-ItemProperty -Times 1
            }
        }
    }

    Context 'When backup item has null value' {
        It 'Should call Remove-ItemProperty to delete the value' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'restore.log'
                Mock -CommandName Write-Host
                Mock -CommandName Remove-ItemProperty

                $backup = [PSCustomObject]@{
                    Timestamp   = '2026-01-01T10:00:00'
                    Mitigations = @(
                        [PSCustomObject]@{
                            Name         = 'RemovedMit'
                            RegistryPath = 'HKLM:\SOFTWARE\Test'
                            RegistryName = 'OldVal'
                            Value        = $null
                        }
                    )
                }

                $WhatIfPreference = $false
                Restore-Configuration -Backup $backup
                Should -Invoke -CommandName Remove-ItemProperty -Times 1
            }
        }
    }
}
