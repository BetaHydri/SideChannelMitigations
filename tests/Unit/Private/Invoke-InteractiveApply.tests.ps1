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

Describe 'Invoke-InteractiveApply' -Skip:(-not $builtModule) {
    Context 'Function existence' {
        It 'Should exist as a private function in the module' {
            InModuleScope $script:moduleName {
                Get-Command -Name 'Invoke-InteractiveApply' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Selective backup on apply' {
        It 'Should back up only the selected mitigations, not all' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'apply.log'
                $script:BackupPath = $TestDrive

                # Define 3 mitigations but user selects only 2
                $allMitigations = @(
                    @{
                        Id           = 'MIT1'
                        Name         = 'Mitigation One'
                        RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                        RegistryName = 'Val1'
                        EnabledValue = 1
                        Impact       = 'Low'
                    }
                    @{
                        Id           = 'MIT2'
                        Name         = 'Mitigation Two'
                        RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                        RegistryName = 'Val2'
                        EnabledValue = 1
                        Impact       = 'Low'
                    }
                    @{
                        Id           = 'MIT3'
                        Name         = 'Mitigation Three'
                        RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                        RegistryName = 'Val3'
                        EnabledValue = 1
                        Impact       = 'Low'
                    }
                )

                # User selects items 1 and 3 (MIT1, MIT3)
                $results = @(
                    [PSCustomObject]@{
                        Id             = 'MIT1'
                        Name           = 'Mitigation One'
                        OverallStatus  = 'Vulnerable'
                        ActionNeeded   = 'Yes - Recommended'
                        Impact         = 'Low'
                        Recommendation = 'Apply'
                    }
                    [PSCustomObject]@{
                        Id             = 'MIT2'
                        Name           = 'Mitigation Two'
                        OverallStatus  = 'Vulnerable'
                        ActionNeeded   = 'Yes - Recommended'
                        Impact         = 'Low'
                        Recommendation = 'Apply'
                    }
                    [PSCustomObject]@{
                        Id             = 'MIT3'
                        Name           = 'Mitigation Three'
                        OverallStatus  = 'Vulnerable'
                        ActionNeeded   = 'Yes - Recommended'
                        Impact         = 'Low'
                        Recommendation = 'Apply'
                    }
                )

                Mock -CommandName Write-Host
                Mock -CommandName Get-StatusIcon { return '*' }
                Mock -CommandName Read-Host -MockWith {
                    # First call: view mode, second: selection, third: confirm
                    $script:readHostCallCount++
                    switch ($script:readHostCallCount) {
                        1 { return 'R' }
                        2 { return '1,3' }
                        3 { return 'Y' }
                    }
                }
                Mock -CommandName Get-SideChannelMitigationDefinition { return $allMitigations }
                Mock -CommandName Set-MitigationValue { return $true }

                # Track what New-SideChannelBackup receives
                $script:capturedBackupMitigations = $null
                Mock -CommandName New-SideChannelBackup {
                    $script:capturedBackupMitigations = $Mitigations
                    return (Join-Path $TestDrive 'Backup_test.json')
                }

                $script:readHostCallCount = 0
                Invoke-InteractiveApply -Results $results

                # The backup should contain only MIT1 and MIT3 (the selected ones)
                $script:capturedBackupMitigations | Should -HaveCount 2
                $script:capturedBackupMitigations.Id | Should -Contain 'MIT1'
                $script:capturedBackupMitigations.Id | Should -Contain 'MIT3'
                $script:capturedBackupMitigations.Id | Should -Not -Contain 'MIT2'
            }
        }

        It 'Should back up all shown mitigations when user selects all' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'apply.log'
                $script:BackupPath = $TestDrive

                $allMitigations = @(
                    @{
                        Id           = 'MIT1'
                        Name         = 'Mitigation One'
                        RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                        RegistryName = 'Val1'
                        EnabledValue = 1
                        Impact       = 'Low'
                    }
                    @{
                        Id           = 'MIT2'
                        Name         = 'Mitigation Two'
                        RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                        RegistryName = 'Val2'
                        EnabledValue = 1
                        Impact       = 'Low'
                    }
                )

                $results = @(
                    [PSCustomObject]@{
                        Id             = 'MIT1'
                        Name           = 'Mitigation One'
                        OverallStatus  = 'Vulnerable'
                        ActionNeeded   = 'Yes - Recommended'
                        Impact         = 'Low'
                        Recommendation = 'Apply'
                    }
                    [PSCustomObject]@{
                        Id             = 'MIT2'
                        Name           = 'Mitigation Two'
                        OverallStatus  = 'Vulnerable'
                        ActionNeeded   = 'Yes - Recommended'
                        Impact         = 'Low'
                        Recommendation = 'Apply'
                    }
                )

                Mock -CommandName Write-Host
                Mock -CommandName Get-StatusIcon { return '*' }
                Mock -CommandName Read-Host -MockWith {
                    $script:readHostCallCount++
                    switch ($script:readHostCallCount) {
                        1 { return 'R' }
                        2 { return 'all' }
                        3 { return 'Y' }
                    }
                }
                Mock -CommandName Get-SideChannelMitigationDefinition { return $allMitigations }
                Mock -CommandName Set-MitigationValue { return $true }

                $script:capturedBackupMitigations = $null
                Mock -CommandName New-SideChannelBackup {
                    $script:capturedBackupMitigations = $Mitigations
                    return (Join-Path $TestDrive 'Backup_test.json')
                }

                $script:readHostCallCount = 0
                Invoke-InteractiveApply -Results $results

                # When selecting 'all', backup should contain both selected mitigations
                $script:capturedBackupMitigations | Should -HaveCount 2
            }
        }
    }

    Context 'WhatIf mode' {
        It 'Should indicate selective backup in WhatIf output' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'apply.log'

                $results = @(
                    [PSCustomObject]@{
                        Id             = 'MIT1'
                        Name           = 'Mitigation One'
                        OverallStatus  = 'Vulnerable'
                        ActionNeeded   = 'Yes - Recommended'
                        Impact         = 'Low'
                        Recommendation = 'Apply'
                    }
                )

                Mock -CommandName Write-Host
                Mock -CommandName Get-StatusIcon { return '*' }
                Mock -CommandName Read-Host -MockWith {
                    $script:readHostCallCount++
                    switch ($script:readHostCallCount) {
                        1 { return 'R' }
                        2 { return '1' }
                    }
                }
                Mock -CommandName Get-SideChannelMitigationDefinition {
                    return @(
                        @{
                            Id           = 'MIT1'
                            Name         = 'Mitigation One'
                            RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                            RegistryName = 'Val1'
                            EnabledValue = 1
                            Impact       = 'Low'
                        }
                    )
                }

                $WhatIfPreference = $true
                $script:readHostCallCount = 0
                Invoke-InteractiveApply -Results $results

                Should -Invoke -CommandName Write-Host -ParameterFilter {
                    $Object -match 'selected mitigations only'
                } -Times 1
            }
        }
    }
}
