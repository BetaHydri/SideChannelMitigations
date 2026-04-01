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

Describe 'Get-StatusIcon' {
    Context 'Returns valid Unicode characters' {
        It 'Should return a non-empty string for Success' {
            InModuleScope $script:moduleName {
                $result = Get-StatusIcon -Name 'Success'
                $result | Should -Not -BeNullOrEmpty
                $result.Length | Should -BeGreaterOrEqual 1
            }
        }

        It 'Should return a non-empty string for Error' {
            InModuleScope $script:moduleName {
                $result = Get-StatusIcon -Name 'Error'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should return a non-empty string for Warning' {
            InModuleScope $script:moduleName {
                $result = Get-StatusIcon -Name 'Warning'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should return a non-empty string for BlockFull' {
            InModuleScope $script:moduleName {
                $result = Get-StatusIcon -Name 'BlockFull'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should return a non-empty string for BlockLight' {
            InModuleScope $script:moduleName {
                $result = Get-StatusIcon -Name 'BlockLight'
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'All valid icon names return values' {
        BeforeAll {
            $script:validNames = @(
                'Success', 'Error', 'Warning', 'Info',
                'Check', 'Cross', 'Bullet',
                'RedCircle', 'YellowCircle', 'GreenCircle',
                'BlockFull', 'BlockLight'
            )
        }

        It 'Should return a value for icon name <_>' -ForEach @(
            'Success', 'Error', 'Warning', 'Info',
            'Check', 'Cross', 'Bullet',
            'BlockFull', 'BlockLight'
        ) {
            InModuleScope $script:moduleName -Parameters @{ IconName = $_ } {
                $result = Get-StatusIcon -Name $IconName
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}