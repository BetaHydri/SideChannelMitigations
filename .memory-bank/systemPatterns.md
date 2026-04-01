# System Patterns

## Module Architecture
- **Sampler/ModuleBuilder** compiles `source/` into a single `.psm1` at build time
- `source/prefix.ps1` provides module-scoped variables (`$script:RuntimeState`, `$script:PlatformInfo`, `$script:HardwareInfo`, paths)
- `source/Public/` — 5 exported functions (Verb-Noun with module noun prefix)
- `source/Private/` — 26 internal functions (original names preserved)
- `source/SideChannelMitigations.psm1` — empty placeholder (ModuleBuilder populates)

## Naming Conventions
- Public functions use `SideChannel` prefix: `Invoke-SideChannelAssessment`, `Get-SideChannelMitigationDefinition`, `New-SideChannelBackup`, `Export-SideChannelAssessment`, `Restore-SideChannelBackup`
- Private functions keep domain-specific names: `Initialize-RuntimeDetection`, `Get-RuntimeMitigationStatus`, `Compare-MitigationValue`, etc.

## Key Design Patterns
- **Mitigation Registry Pattern**: `Get-SideChannelMitigationDefinition` returns array of hashtables defining all mitigations with metadata (Id, CVE, RegistryPath, EnabledValue, RuntimeDetection, etc.)
- **Runtime Detection**: NtQuerySystemInformation API (class 201) reads kernel flags for actual mitigation state
- **Platform Awareness**: `Initialize-PlatformDetection` sets `$script:PlatformInfo.Type` to Physical/HyperVHost/HyperVGuest/VMwareGuest; mitigations filtered by `Test-PlatformApplicability`
- **Backup/Restore**: JSON-based backup files in `$script:BackupPath` with full metadata

## Test Strategy
- **QA tests** (`tests/QA/`): Module import/export, changelog format
- **Unit tests** (`tests/Unit/Public/`): Function definition verification, parameter validation
- **Unit tests** (`tests/Unit/Private/`): Pure logic testing via `InModuleScope` (Compare-MitigationValue, Get-OverallStatus, Get-ActionNeeded, Test-PlatformApplicability, Get-StatusIcon, Get-RuntimeMitigationStatus)
- All tests are Windows-only (no Linux testing needed)
- All test files use UTF-8 BOM encoding