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
        . "$sourcePath\prefix.ps1"
        Get-ChildItem -Path "$sourcePath\Private\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }
        Get-ChildItem -Path "$sourcePath\Public\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }
    }
}

Describe 'Test-PlatformApplicability' {
    Context 'When TargetPlatform is All' {
        It 'Should return true for any platform type' {
            InModuleScope $script:moduleName {
                $script:PlatformInfo = @{ Type = 'Physical'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'All' | Should -BeTrue

                $script:PlatformInfo = @{ Type = 'HyperVHost'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'All' | Should -BeTrue

                $script:PlatformInfo = @{ Type = 'VMwareGuest'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'All' | Should -BeTrue
            }
        }
    }

    Context 'When TargetPlatform is Physical' {
        It 'Should return true for Physical platform' {
            InModuleScope $script:moduleName {
                $script:PlatformInfo = @{ Type = 'Physical'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'Physical' | Should -BeTrue
            }
        }

        It 'Should return true for HyperVHost (physical with Hyper-V)' {
            InModuleScope $script:moduleName {
                $script:PlatformInfo = @{ Type = 'HyperVHost'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'Physical' | Should -BeTrue
            }
        }

        It 'Should return false for VMwareGuest' {
            InModuleScope $script:moduleName {
                $script:PlatformInfo = @{ Type = 'VMwareGuest'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'Physical' | Should -BeFalse
            }
        }
    }

    Context 'When TargetPlatform is HyperVHost' {
        It 'Should return true only for HyperVHost' {
            InModuleScope $script:moduleName {
                $script:PlatformInfo = @{ Type = 'HyperVHost'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'HyperVHost' | Should -BeTrue

                $script:PlatformInfo = @{ Type = 'Physical'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'HyperVHost' | Should -BeFalse
            }
        }
    }

    Context 'When TargetPlatform is VirtualMachine' {
        It 'Should return true for Guest types' {
            InModuleScope $script:moduleName {
                $script:PlatformInfo = @{ Type = 'HyperVGuest'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'VirtualMachine' | Should -BeTrue

                $script:PlatformInfo = @{ Type = 'VMwareGuest'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'VirtualMachine' | Should -BeTrue

                $script:PlatformInfo = @{ Type = 'VirtualMachine'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'VirtualMachine' | Should -BeTrue
            }
        }

        It 'Should return false for Physical' {
            InModuleScope $script:moduleName {
                $script:PlatformInfo = @{ Type = 'Physical'; Details = @{} }
                Test-PlatformApplicability -TargetPlatform 'VirtualMachine' | Should -BeFalse
            }
        }
    }
}