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

Describe 'Export-SideChannelAssessment' -Skip:(-not $builtModule) {
    Context 'Function definition' {
        It 'Should be exported from the module' {
            $cmd = Get-Command -Name 'Export-SideChannelAssessment' -Module $script:moduleName -ErrorAction SilentlyContinue
            $cmd | Should -Not -BeNullOrEmpty
        }

        It 'Should have Results and Path parameters' {
            $cmd = Get-Command -Name 'Export-SideChannelAssessment' -Module $script:moduleName
            $cmd.Parameters.ContainsKey('Results') | Should -BeTrue
            $cmd.Parameters.ContainsKey('Path') | Should -BeTrue
        }
    }

    Context 'CSV export' {
        BeforeAll {
            $script:tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "SideChannelTest_$(Get-Random)"
            New-Item -Path $script:tempDir -ItemType Directory -Force | Out-Null
        }

        AfterAll {
            if (Test-Path $script:tempDir) {
                Remove-Item $script:tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Should create a CSV file with correct structure' {
            InModuleScope $script:moduleName -Parameters @{ ExportDir = $script:tempDir } {
                # Create mock results
                $mockResults = @(
                    [PSCustomObject]@{
                        Id             = 'TEST1'
                        Name           = 'Test Mitigation 1'
                        CVE            = 'CVE-2024-0001'
                        Category       = 'Critical'
                        RegistryStatus = 'Enabled'
                        RuntimeStatus  = 'Active'
                        OverallStatus  = 'Protected'
                        ActionNeeded   = 'No'
                        CurrentValue   = 1
                        ExpectedValue  = 1
                        Impact         = 'Low'
                        Description    = 'Test description'
                        Recommendation = 'Test recommendation'
                        RegistryPath   = 'HKLM:\Test'
                        RegistryName   = 'TestValue'
                        URL            = 'https://example.com'
                    }
                )

                # Mock Get-SideChannelMitigationDefinition
                Mock Get-SideChannelMitigationDefinition {
                    return @(
                        @{
                            Id       = 'TEST1'
                            Platform = 'All'
                        }
                    )
                }

                # Mock Write-Log to suppress output
                Mock Write-Log {}

                Export-SideChannelAssessment -Results $mockResults -Path $ExportDir

                $csvFiles = Get-ChildItem -Path $ExportDir -Filter 'SideChannelAssessment_*.csv'
                $csvFiles | Should -Not -BeNullOrEmpty
                $csvContent = Get-Content $csvFiles[0].FullName -Raw
                $csvContent | Should -Not -BeNullOrEmpty
            }
        }
    }
}