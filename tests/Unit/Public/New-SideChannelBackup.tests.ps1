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

Describe 'New-SideChannelBackup' -Skip:(-not $builtModule) {
    Context 'Function definition' {
        It 'Should be exported from the module' {
            $cmd = Get-Command -Name 'New-SideChannelBackup' -Module $script:moduleName -ErrorAction SilentlyContinue
            $cmd | Should -Not -BeNullOrEmpty
        }

        It 'Should have a Mitigations parameter' {
            $cmd = Get-Command -Name 'New-SideChannelBackup' -Module $script:moduleName
            $cmd.Parameters.ContainsKey('Mitigations') | Should -BeTrue
        }
    }

    Context 'Backup creation' {
        BeforeAll {
            $script:tempBackupDir = Join-Path ([System.IO.Path]::GetTempPath()) "SideChannelTest_$(Get-Random)"
            New-Item -Path $script:tempBackupDir -ItemType Directory -Force | Out-Null
        }

        AfterAll {
            if (Test-Path $script:tempBackupDir) {
                Remove-Item $script:tempBackupDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Should create a JSON backup file' {
            InModuleScope $script:moduleName -Parameters @{ BackupDir = $script:tempBackupDir } {
                $script:BackupPath = $BackupDir

                $testMitigations = @(
                    @{
                        Id           = 'TEST1'
                        Name         = 'Test Mitigation'
                        RegistryPath = 'HKLM:\SOFTWARE\TestPath'
                        RegistryName = 'TestValue'
                    }
                )

                $result = New-SideChannelBackup -Mitigations $testMitigations

                $result | Should -Not -BeNullOrEmpty
                Test-Path $result | Should -BeTrue
                $result | Should -Match '\.json$'

                $content = Get-Content $result -Raw | ConvertFrom-Json
                $content.Computer | Should -Be $env:COMPUTERNAME
                $content.User | Should -Be $env:USERNAME
            }
        }
    }
}