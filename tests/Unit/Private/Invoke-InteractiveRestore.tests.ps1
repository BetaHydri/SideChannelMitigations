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

Describe 'Invoke-InteractiveRestore' -Skip:(-not $builtModule) {
    Context 'Function existence' {
        It 'Should exist as a private function in the module' {
            InModuleScope $script:moduleName {
                Get-Command -Name 'Invoke-InteractiveRestore' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Displays only mitigations from selected backup' {
        It 'Should show only 2 items when backup contains 2 mitigations' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'restore.log'

                # A selective backup with only 2 mitigations
                $backup = [PSCustomObject]@{
                    Timestamp   = '2026-01-01T10:00:00'
                    Computer    = 'TESTPC'
                    User        = 'testuser'
                    Mitigations = @(
                        [PSCustomObject]@{
                            Id           = 'MIT1'
                            Name         = 'Mitigation One'
                            RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                            RegistryName = 'Val1'
                            Value        = 1
                        }
                        [PSCustomObject]@{
                            Id           = 'MIT2'
                            Name         = 'Mitigation Two'
                            RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                            RegistryName = 'Val2'
                            Value        = $null
                        }
                    )
                }

                $script:writeHostCalls = @()
                Mock -CommandName Write-Host -MockWith {
                    $script:writeHostCalls += $Object
                }
                Mock -CommandName Get-StatusIcon { return '*' }
                Mock -CommandName Read-Host { return 'Q' }

                Invoke-InteractiveRestore -Backup $backup

                # Only 2 numbered items should be displayed (not 29)
                $numberedItems = $script:writeHostCalls | Where-Object { $_ -match '^\[\d+\] ' }
                $numberedItems | Should -HaveCount 2
            }
        }

        It 'Should show no items and return when backup has only hardware items' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'restore.log'

                $backup = [PSCustomObject]@{
                    Timestamp   = '2026-01-01T10:00:00'
                    Computer    = 'TESTPC'
                    User        = 'testuser'
                    Mitigations = @(
                        [PSCustomObject]@{
                            Id           = 'HW1'
                            Name         = 'Hardware Only'
                            RegistryPath = ''
                            RegistryName = ''
                            Value        = $null
                        }
                    )
                }

                Mock -CommandName Write-Host
                Mock -CommandName Get-StatusIcon { return '*' }

                # Should return without prompting for selection
                Invoke-InteractiveRestore -Backup $backup

                Should -Not -Invoke -CommandName Read-Host
            }
        }
    }

    Context 'Restore only selected items' {
        It 'Should restore only the items the user picks from the backup' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'restore.log'

                $backup = [PSCustomObject]@{
                    Timestamp   = '2026-01-01T10:00:00'
                    Computer    = 'TESTPC'
                    User        = 'testuser'
                    Mitigations = @(
                        [PSCustomObject]@{
                            Id           = 'MIT1'
                            Name         = 'Mitigation One'
                            RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                            RegistryName = 'Val1'
                            Value        = 1
                        }
                        [PSCustomObject]@{
                            Id           = 'MIT2'
                            Name         = 'Mitigation Two'
                            RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                            RegistryName = 'Val2'
                            Value        = 0
                        }
                    )
                }

                Mock -CommandName Write-Host
                Mock -CommandName Get-StatusIcon { return '*' }
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Read-Host -MockWith {
                    $script:readHostCallCount++
                    switch ($script:readHostCallCount) {
                        1 { return '1' }     # Select only first item
                        2 { return 'Y' }     # Confirm
                    }
                }

                $script:readHostCallCount = 0
                Invoke-InteractiveRestore -Backup $backup

                # Only 1 registry write should occur (item 1 only)
                Should -Invoke -CommandName Set-ItemProperty -Times 1
            }
        }
    }
}
