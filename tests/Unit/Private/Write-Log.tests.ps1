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

Describe 'Write-Log' -Skip:(-not $builtModule) {
    Context 'Function existence' {
        It 'Should exist as a private function in the module' {
            InModuleScope $script:moduleName {
                Get-Command -Name 'Write-Log' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Log file writing' {
        BeforeAll {
            $script:testLogFile = Join-Path $TestDrive 'test.log'
        }

        It 'Should write a log entry to the log file' {
            InModuleScope $script:moduleName -Parameters @{ logFile = $script:testLogFile } {
                param($logFile)
                $script:LogPath = $logFile
                Write-Log -Message 'Test message' -Level Info -NoConsole
            }
            $script:testLogFile | Should -Exist
            Get-Content $script:testLogFile | Should -Match 'Test message'
        }

        It 'Should include the level in the log entry' {
            InModuleScope $script:moduleName -Parameters @{ logFile = $script:testLogFile } {
                param($logFile)
                $script:LogPath = $logFile
                Write-Log -Message 'Warning test' -Level Warning -NoConsole
            }
            Get-Content $script:testLogFile | Select-Object -Last 1 | Should -Match '\[Warning\]'
        }

        It 'Should include a timestamp in the log entry' {
            InModuleScope $script:moduleName -Parameters @{ logFile = $script:testLogFile } {
                param($logFile)
                $script:LogPath = $logFile
                Write-Log -Message 'Timestamp test' -Level Info -NoConsole
            }
            Get-Content $script:testLogFile | Select-Object -Last 1 | Should -Match '\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]'
        }

        It 'Should append multiple entries to the same file' {
            $multiLogFile = Join-Path $TestDrive 'multi.log'
            InModuleScope $script:moduleName -Parameters @{ logFile = $multiLogFile } {
                param($logFile)
                $script:LogPath = $logFile
                Write-Log -Message 'First' -Level Info -NoConsole
                Write-Log -Message 'Second' -Level Success -NoConsole
                Write-Log -Message 'Third' -Level Error -NoConsole
            }
            (Get-Content $multiLogFile).Count | Should -Be 3
        }
    }

    Context 'Console output suppression' {
        It 'Should suppress console output when -NoConsole is specified' {
            InModuleScope $script:moduleName {
                $script:LogPath = Join-Path $TestDrive 'noconsole.log'
                Mock -CommandName Write-Host
                Write-Log -Message 'Silent' -Level Info -NoConsole
                Should -Invoke -CommandName Write-Host -Times 0
            }
        }
    }
}
