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

Describe 'Get-RuntimeMitigationStatus' -Skip:(-not $builtModule) {
    Context 'When API is not available' {
        It 'Should return N/A for any mitigation' {
            InModuleScope $script:moduleName {
                $script:RuntimeState = @{ APIAvailable = $false; Flags = @{} }

                Get-RuntimeMitigationStatus -MitigationId 'BTI' | Should -Be 'N/A'
                Get-RuntimeMitigationStatus -MitigationId 'KVAS' | Should -Be 'N/A'
                Get-RuntimeMitigationStatus -MitigationId 'SSBD' | Should -Be 'N/A'
            }
        }
    }

    Context 'When API is available with BTI mitigations' {
        It 'Should return Active (Enhanced IBRS) when Enhanced IBRS is enabled' {
            InModuleScope $script:moduleName {
                $script:RuntimeState = @{
                    APIAvailable = $true
                    Flags = @{
                        BTIEnabled    = $true
                        EnhancedIBRS  = $true
                        RetpolineEnabled = $false
                    }
                }

                Get-RuntimeMitigationStatus -MitigationId 'BTI' | Should -Be 'Active (Enhanced IBRS)'
            }
        }

        It 'Should return Active (Retpoline) when Retpoline is enabled' {
            InModuleScope $script:moduleName {
                $script:RuntimeState = @{
                    APIAvailable = $true
                    Flags = @{
                        BTIEnabled       = $true
                        EnhancedIBRS     = $false
                        RetpolineEnabled = $true
                    }
                }

                Get-RuntimeMitigationStatus -MitigationId 'BTI' | Should -Be 'Active (Retpoline)'
            }
        }

        It 'Should return Inactive when no BTI protection is active' {
            InModuleScope $script:moduleName {
                $script:RuntimeState = @{
                    APIAvailable = $true
                    Flags = @{
                        BTIEnabled       = $false
                        EnhancedIBRS     = $false
                        RetpolineEnabled = $false
                    }
                }

                Get-RuntimeMitigationStatus -MitigationId 'BTI' | Should -Be 'Inactive'
            }
        }
    }

    Context 'When API is available with KVAS mitigations' {
        It 'Should return Not Needed (HW Immune) when hardware is protected' {
            InModuleScope $script:moduleName {
                $script:RuntimeState = @{
                    APIAvailable = $true
                    Flags = @{
                        RDCLHardwareProtected = $true
                        KVAShadowEnabled      = $false
                    }
                }

                Get-RuntimeMitigationStatus -MitigationId 'KVAS' | Should -Be 'Not Needed (HW Immune)'
            }
        }

        It 'Should return Active when KVAS is enabled' {
            InModuleScope $script:moduleName {
                $script:RuntimeState = @{
                    APIAvailable = $true
                    Flags = @{
                        RDCLHardwareProtected = $false
                        KVAShadowEnabled      = $true
                    }
                }

                Get-RuntimeMitigationStatus -MitigationId 'KVAS' | Should -Be 'Active'
            }
        }
    }

    Context 'Unknown mitigation ID' {
        It 'Should return N/A for unknown mitigation' {
            InModuleScope $script:moduleName {
                $script:RuntimeState = @{ APIAvailable = $true; Flags = @{} }

                Get-RuntimeMitigationStatus -MitigationId 'UNKNOWN' | Should -Be 'N/A'
            }
        }
    }
}