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
        # Dot-source for development without build
        $sourcePath = Join-Path $projectPath 'source'
        Get-ChildItem -Path "$sourcePath\Private\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }
        Get-ChildItem -Path "$sourcePath\Public\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object { . $_.FullName }
    }
}

Describe 'Get-SideChannelMitigationDefinition' {
    Context 'When called without parameters' {
        BeforeAll {
            $script:definitions = Get-SideChannelMitigationDefinition
        }

        It 'Should return an array of mitigation definitions' {
            $script:definitions | Should -Not -BeNullOrEmpty
            $script:definitions.Count | Should -BeGreaterThan 10
        }

        It 'Should include Critical mitigations' {
            $critical = @($script:definitions | Where-Object { $_.Category -eq 'Critical' })
            $critical.Count | Should -BeGreaterThan 0
        }

        It 'Should include Prerequisite entries' {
            $prereqs = @($script:definitions | Where-Object { $_.Category -eq 'Prerequisite' })
            $prereqs.Count | Should -BeGreaterThan 0
        }

        It 'Each definition should have required properties' {
            foreach ($def in $script:definitions) {
                $def.Id | Should -Not -BeNullOrEmpty
                $def.Name | Should -Not -BeNullOrEmpty
                $def.Category | Should -Not -BeNullOrEmpty
                $def.Description | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should include the SSBD mitigation' {
            $ssbd = $script:definitions | Where-Object { $_.Id -eq 'SSBD' }
            $ssbd | Should -Not -BeNullOrEmpty
            $ssbd.CVE | Should -Match 'CVE-2018-3639'
        }

        It 'Should include the KVAS mitigation' {
            $kvas = $script:definitions | Where-Object { $_.Id -eq 'KVAS' }
            $kvas | Should -Not -BeNullOrEmpty
            $kvas.CVE | Should -Match 'Meltdown'
        }

        It 'Should include TPM prerequisite' {
            $tpm = $script:definitions | Where-Object { $_.Id -eq 'TPM' }
            $tpm | Should -Not -BeNullOrEmpty
            $tpm.IsPrerequisite | Should -BeTrue
        }

        It 'Should have valid registry paths for non-prerequisite items' {
            $registryItems = @($script:definitions | Where-Object {
                $_.Category -ne 'Prerequisite' -or
                ($_.RegistryPath -and $_.RegistryName)
            })
            foreach ($item in $registryItems) {
                if ($item.RegistryPath) {
                    $item.RegistryPath | Should -Match '^HKLM:\\'
                }
            }
        }

        It 'All categories should be valid' {
            $validCategories = @('Critical', 'Recommended', 'Optional', 'Prerequisite')
            foreach ($def in $script:definitions) {
                $def.Category | Should -BeIn $validCategories
            }
        }
    }
}