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

Describe 'Restore-SideChannelBackup' -Skip:(-not $builtModule) {
    Context 'Function definition' {
        It 'Should be exported from the module' {
            $cmd = Get-Command -Name 'Restore-SideChannelBackup' -Module $script:moduleName -ErrorAction SilentlyContinue
            $cmd | Should -Not -BeNullOrEmpty
        }

        It 'Should support ShouldProcess' {
            $cmd = Get-Command -Name 'Restore-SideChannelBackup' -Module $script:moduleName
            $cmd.Parameters.ContainsKey('WhatIf') | Should -BeTrue
        }

        It 'Should have Path and Latest parameter sets' {
            $cmd = Get-Command -Name 'Restore-SideChannelBackup' -Module $script:moduleName
            $cmd.Parameters.ContainsKey('Path') | Should -BeTrue
            $cmd.Parameters.ContainsKey('Latest') | Should -BeTrue
        }
    }
}