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

Describe 'Invoke-SideChannelAssessment' -Skip:(-not $builtModule) {
    Context 'Function definition' {
        It 'Should be exported from the module' {
            $cmd = Get-Command -Name 'Invoke-SideChannelAssessment' -Module $script:moduleName -ErrorAction SilentlyContinue
            $cmd | Should -Not -BeNullOrEmpty
        }

        It 'Should have CmdletBinding attribute' {
            $cmd = Get-Command -Name 'Invoke-SideChannelAssessment' -Module $script:moduleName
            $cmd.CmdletBinding | Should -BeTrue
        }

        It 'Should support ShouldProcess' {
            $cmd = Get-Command -Name 'Invoke-SideChannelAssessment' -Module $script:moduleName
            $cmd.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $cmd.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'Should have a Mode parameter with ValidateSet' {
            $cmd = Get-Command -Name 'Invoke-SideChannelAssessment' -Module $script:moduleName
            $cmd.Parameters.ContainsKey('Mode') | Should -BeTrue
            $validateSet = $cmd.Parameters['Mode'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'Assess'
            $validateSet.ValidValues | Should -Contain 'ApplyInteractive'
            $validateSet.ValidValues | Should -Contain 'Revert'
            $validateSet.ValidValues | Should -Contain 'Backup'
            $validateSet.ValidValues | Should -Contain 'RestoreInteractive'
        }

        It 'Should have an ExportPath parameter' {
            $cmd = Get-Command -Name 'Invoke-SideChannelAssessment' -Module $script:moduleName
            $cmd.Parameters.ContainsKey('ExportPath') | Should -BeTrue
        }

        It 'Should have a ShowDetails switch' {
            $cmd = Get-Command -Name 'Invoke-SideChannelAssessment' -Module $script:moduleName
            $cmd.Parameters.ContainsKey('ShowDetails') | Should -BeTrue
            $cmd.Parameters['ShowDetails'].ParameterType | Should -Be ([switch])
        }
    }
}