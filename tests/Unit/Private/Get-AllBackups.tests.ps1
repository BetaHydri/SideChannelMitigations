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

Describe 'Get-AllBackups' -Skip:(-not $builtModule) {
    Context 'Function existence' {
        It 'Should exist as a private function in the module' {
            InModuleScope $script:moduleName {
                Get-Command -Name 'Get-AllBackups' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When no backups exist' {
        It 'Should return an empty array' {
            InModuleScope $script:moduleName {
                $script:BackupPath = Join-Path $TestDrive 'EmptyBackups'
                New-Item -Path $script:BackupPath -ItemType Directory -Force | Out-Null
                $result = Get-AllBackups
                $result | Should -HaveCount 0
            }
        }
    }

    Context 'When backups exist' {
        BeforeAll {
            $script:backupDir = Join-Path $TestDrive 'Backups'
            New-Item -Path $script:backupDir -ItemType Directory -Force | Out-Null

            $backup1 = @{
                Timestamp   = '2026-01-01T10:00:00'
                Computer    = 'SERVER01'
                User        = 'admin'
                Mitigations = @(
                    @{ Name = 'SSBD'; RegistryPath = 'HKLM:\Test'; RegistryName = 'Val'; Value = 1 }
                )
            }
            $backup2 = @{
                Timestamp   = '2026-02-01T10:00:00'
                Computer    = 'SERVER01'
                User        = 'admin'
                Mitigations = @(
                    @{ Name = 'SSBD'; RegistryPath = 'HKLM:\Test'; RegistryName = 'Val'; Value = 1 }
                    @{ Name = 'BTI'; RegistryPath = 'HKLM:\Test'; RegistryName = 'Val2'; Value = 0 }
                )
            }

            $backup1 | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:backupDir 'Backup_20260101_100000.json')
            $backup2 | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:backupDir 'Backup_20260201_100000.json')
        }

        It 'Should return all backup files' {
            InModuleScope $script:moduleName -Parameters @{ dir = $script:backupDir } {
                param($dir)
                $script:BackupPath = $dir
                $result = Get-AllBackups
                $result | Should -HaveCount 2
            }
        }

        It 'Should return backups sorted by date descending' {
            InModuleScope $script:moduleName -Parameters @{ dir = $script:backupDir } {
                param($dir)
                $script:BackupPath = $dir
                $result = Get-AllBackups
                $result[0].FileName | Should -BeLike '*20260201*'
            }
        }

        It 'Should parse backup metadata correctly' {
            InModuleScope $script:moduleName -Parameters @{ dir = $script:backupDir } {
                param($dir)
                $script:BackupPath = $dir
                $result = Get-AllBackups
                $result[0].Computer | Should -Be 'SERVER01'
                $result[0].User | Should -Be 'admin'
                $result[0].MitigationCount | Should -Be 2
            }
        }
    }

    Context 'When backup file is corrupt' {
        It 'Should skip invalid JSON files and continue' {
            InModuleScope $script:moduleName {
                $corruptDir = Join-Path $TestDrive 'CorruptBackups'
                New-Item -Path $corruptDir -ItemType Directory -Force | Out-Null
                Set-Content (Join-Path $corruptDir 'Backup_20260101_100000.json') -Value 'NOT VALID JSON {'

                $validBackup = @{
                    Timestamp   = '2026-03-01T10:00:00'
                    Computer    = 'SERVER02'
                    User        = 'admin'
                    Mitigations = @()
                }
                $validBackup | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $corruptDir 'Backup_20260301_100000.json')

                Mock -CommandName Write-Log

                $script:BackupPath = $corruptDir
                $result = Get-AllBackups
                $result | Should -HaveCount 1
                $result[0].Computer | Should -Be 'SERVER02'
            }
        }
    }
}
