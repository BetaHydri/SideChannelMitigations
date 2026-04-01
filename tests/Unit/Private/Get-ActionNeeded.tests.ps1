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

Describe 'Get-ActionNeeded' {
    Context 'When overall status is Protected' {
        It 'Should return No for any category when Protected' {
            InModuleScope $script:moduleName {
                Get-ActionNeeded -Category 'Critical' -OverallStatus 'Protected' | Should -Be 'No'
                Get-ActionNeeded -Category 'Recommended' -OverallStatus 'Protected' | Should -Be 'No'
                Get-ActionNeeded -Category 'Optional' -OverallStatus 'Protected' | Should -Be 'No'
            }
        }
    }

    Context 'When overall status is Vulnerable' {
        It 'Should return Yes - Critical for Critical category' {
            InModuleScope $script:moduleName {
                Get-ActionNeeded -Category 'Critical' -OverallStatus 'Vulnerable' | Should -Be 'Yes - Critical'
            }
        }

        It 'Should return Yes - Recommended for Recommended category' {
            InModuleScope $script:moduleName {
                Get-ActionNeeded -Category 'Recommended' -OverallStatus 'Vulnerable' | Should -Be 'Yes - Recommended'
            }
        }

        It 'Should return Consider for Optional category' {
            InModuleScope $script:moduleName {
                Get-ActionNeeded -Category 'Optional' -OverallStatus 'Vulnerable' | Should -Be 'Consider'
            }
        }
    }
}