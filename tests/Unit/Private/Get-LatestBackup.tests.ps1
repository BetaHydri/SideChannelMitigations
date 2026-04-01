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

Describe 'Get-LatestBackup' -Skip:(-not $builtModule) {
    Context 'Function existence' {
        It 'Should exist as a private function in the module' {
            InModuleScope $script:moduleName {
                Get-Command -Name 'Get-LatestBackup' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When no backups exist' {
        It 'Should return null' {
            InModuleScope $script:moduleName {
                $script:BackupPath = Join-Path $TestDrive 'EmptyLatest'
                New-Item -Path $script:BackupPath -ItemType Directory -Force | Out-Null
                $result = Get-LatestBackup
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When multiple backups exist' {
        BeforeAll {
            $script:backupDir = Join-Path $TestDrive 'LatestBackups'
            New-Item -Path $script:backupDir -ItemType Directory -Force | Out-Null

            $older = @{
                Timestamp   = '2026-01-01T10:00:00'
                Computer    = 'OLD'
                User        = 'admin'
                Mitigations = @()
            }
            $newer = @{
                Timestamp   = '2026-03-15T10:00:00'
                Computer    = 'NEWEST'
                User        = 'admin'
                Mitigations = @()
            }

            $older | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:backupDir 'Backup_20260101_100000.json')
            # Write the newer file with a slight delay to ensure different LastWriteTime
            $newer | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $script:backupDir 'Backup_20260315_100000.json')
            (Get-Item (Join-Path $script:backupDir 'Backup_20260315_100000.json')).LastWriteTime = (Get-Date).AddSeconds(1)
        }

        It 'Should return the most recent backup' {
            InModuleScope $script:moduleName -Parameters @{ dir = $script:backupDir } {
                param($dir)
                $script:BackupPath = $dir
                $result = Get-LatestBackup
                $result | Should -Not -BeNullOrEmpty
                $result.Computer | Should -Be 'NEWEST'
            }
        }

        It 'Should return an object with Timestamp property' {
            InModuleScope $script:moduleName -Parameters @{ dir = $script:backupDir } {
                param($dir)
                $script:BackupPath = $dir
                $result = Get-LatestBackup
                $result.Timestamp | Should -Not -BeNullOrEmpty
            }
        }
    }
}
