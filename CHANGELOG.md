# Changelog for SideChannelMitigations

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.5.0] - 2026-04-02

### Fixed

- `Invoke-InteractiveApply` now creates a selective backup containing only the
  mitigations the user chose to apply, instead of backing up all 29 mitigations.
  This ensures `-Mode Revert` and `-Mode RestoreInteractive` display only the
  items that were actually changed.

### Changed

- WhatIf output for `ApplyInteractive` now indicates "selected mitigations only"
  for the backup.
- Added user hint about `-Mode Backup` for creating full backups of all
  mitigations.

### Added

- Unit tests for `Invoke-InteractiveApply` covering selective backup, full
  selection, and WhatIf behavior.
- Unit tests for `Invoke-InteractiveRestore` covering display filtering,
  hardware-only items, and item selection.

## [3.4.0] - 2026-04-02

### Changed

- Display labels for CPU virtualization and IOMMU now adapt to the detected
  architecture: ARM64 shows "ARM VHE" / "SMMU", x86/x64 shows
  "VT-x/AMD-V" / "IOMMU/VT-d".
- Renamed prerequisite `CPU Virtualization (VT-x/AMD-V)` to
  `CPU Virtualization (VT-x/AMD-V/ARM VHE)`.
- Renamed prerequisite `IOMMU/VT-d Support` to
  `IOMMU (VT-d/AMD-Vi/ARM SMMU)`.
- Updated README sample output and hardware feature descriptions to
  include ARM64 equivalents.
- Switched GitVersion mode from ContinuousDelivery to
  ContinuousDeployment for unique preview version numbers.

## [3.3.1] - 2026-04-02

### Fixed

- Changed `Architecture` for SSBD (CVE-2018-3639), SSBD Feature Mask, and
  BTI (CVE-2017-5715) from `'All'` to `'x86'` to eliminate false-positive
  "Yes - Critical" alerts on ARM64 systems. The Windows registry-based
  mitigations (`FeatureSettingsOverride`, `FeatureSettingsOverrideMask`,
  `DisablePageCombining`) are x86/x64-specific mechanisms. ARM64 CPUs
  mitigate these vulnerabilities via firmware (`SMCCC_ARCH_WORKAROUND_1`,
  `SMCCC_ARCH_WORKAROUND_2`). Verified against
  [Arm Security Bulletin](https://developer.arm.com/Arm%20Security%20Center/Speculative%20Processor%20Vulnerability)
  and
  [Microsoft KB4072698](https://support.microsoft.com/en-us/topic/kb4072698).
- Updated Platform Support Matrix in README with x86/x64 architecture notes
  for SSBD and BTI.

### Added

- Arm Security Documentation section in README with links to Arm
  Spectre/Meltdown bulletin, cache speculation white paper, Spectre-BHB
  white paper, and SMCCC specification.
- ARM64 column in HYPERVISOR_CONFIGURATION.md CPU features table.
- Updated vendor guidance in README to include ARM alongside Intel/AMD.

## [3.3.0] - 2026-04-02

### Added

- ARM64 CPU architecture detection in `Initialize-PlatformDetection`.
- Architecture-based filtering in `Get-SideChannelMitigationDefinition` to skip
  x86-only mitigations on ARM64 systems.
- ARM64 architecture display in `Show-PlatformInfo` and assessment output.

## [3.1.0] - 2026-04-01

### Changed

- `LogPath` parameter now accepts a folder path only; log filename is auto-generated.
- Expanded test coverage for logging functions.

### Fixed

- Refactored README for module-first documentation and corrected module references.

## [3.0.0] - 2026-04-01

### Changed

- **BREAKING CHANGE**: Converted from monolithic script to Sampler-based PowerShell module.
- Renamed public functions to follow Verb-Noun naming conventions:
  - `Get-MitigationDefinitions` is now `Get-SideChannelMitigationDefinition`.
  - `New-ConfigurationBackup` is now `New-SideChannelBackup`.
  - `Export-AssessmentResults` is now `Export-SideChannelAssessment`.
  - `Start-SideChannelCheck` is now `Invoke-SideChannelAssessment`.
- Added `Restore-SideChannelBackup` as a dedicated public function.
- `-ExportPath` now accepts a folder path; CSV filename is auto-generated as
  `SideChannelAssessment_<ComputerName>_<yyyyMMdd_HHmmss>.csv`.

### Added

- Sampler build framework integration with ModuleBuilder.
- Pester 5 test suite for PowerShell 5.1 and 7.x (Windows only).
- Azure DevOps pipeline with preview (main branch) and release (tag) stages.
- Module manifest with explicit function exports and PSGallery metadata.
- GitVersion-based semantic versioning.
- Code coverage (JaCoCo) generation with threshold 1%.
- Module usage documentation and Mermaid best practices flowchart in README.

## [2.3.0] - 2025-12-02

### Changed

- **BREAKING CHANGE**: Renamed modes to match their behavior.
- `RevertInteractive` renamed to `Revert` (quick restore of latest backup).
- `Restore` renamed to `RestoreInteractive` (browse backups and selectively restore).

## [2.2.0] - 2025-12-02

### Added

- Intelligent microcode detection for SBDR/PSDP when registry configured but kernel inactive.
- "Inactive (Microcode Update Required)" status with actionable guidance.
- Special VM notes about hypervisor requirements in microcode warning section.

### Changed

- SBDR and PSDP upgraded to Critical category (high-severity CVEs).
- Bright red (ANSI 91) highlighting for Critical vulnerabilities in PowerShell 7+.

## [2.1.9] - 2025-12-02

### Fixed

- FeatureSettingsOverride detection corrected per Microsoft KB4072698.
- Now accepts only documented values: 0x2048, 0x800000, 0x802048.
- Intel CPUs recommend 0x802048 (Basic + BHI); AMD CPUs recommend 0x2048.
- Value 0 no longer accepted (does NOT enable system-wide mitigations).

## [2.1.8] - 2025-12-02

### Fixed

- Attempted SSBD fix (later corrected in v2.1.9).

## [2.1.7] - 2025-12-02

### Fixed

- Corrected all kernel API flag bitmasks to match Microsoft SpeculationControl module.
- KVAS detection now correctly shows "Not Needed (HW Immune)" for Meltdown-immune CPUs.
- Enhanced IBRS bitmask fixed from 0x100 to 0x10000.
- MDS HW Protected bitmask fixed from 0x40000 to 0x1000000.

## [2.1.6] - 2025-12-02

### Added

- Hardware-based detection via NtQuerySystemInformation API (flags2).
- SBDR (0x01), FBSDP (0x02), PSDP (0x04) hardware protection status.
- FBSDP mitigation definition (Fill Buffer Stale Data Propagator).
- AMD/ARM CPUs automatically marked as hardware immune.

### Fixed

- Regex word boundary fix: "Inactive" no longer matches "Active" pattern.

## [2.1.5] - 2025-12-02

### Added

- Hypervisor prerequisite notes to SBDR, SRBDS, and DRPW mitigations.
- Comprehensive VM limitation guidance for all CPU-specific mitigations.

## [2.1.4] - 2025-12-02

### Fixed

- Removed dependency on `Get-WindowsOptionalFeature` (errors on Windows Server).
- Improved VT-x/AMD-V detection with multiple fallback methods.

## [2.1.3] - 2025-12-02

### Fixed

- Hyper-V detection on Windows 11 25H2 using multi-method fallback.

## [2.1.2] - 2025-12-02

### Fixed

- REG_BINARY detection for MitigationOptions after system reboot.
- Automatic byte array to uint64 conversion in Compare-MitigationValue.

## [2.1.1] - 2025-12-01

### Changed

- Enhanced Runtime Status Guide with 5 comprehensive state descriptions.

### Fixed

- Recommendation syntax changed from `-Mode Apply -Interactive` to `-Mode ApplyInteractive`.

## [2.1.0] - 2025-11-26

### Added

- Selective apply and restore with [R]ecommended/[A]ll view modes.
- 22 authoritative URL references for all mitigations (NVD, Microsoft, Intel, AMD).
- Enhanced 7-column detailed table (CVE, Platform, Impact, Required For).
- Dependency mapping with PrerequisiteFor property.
- WhatIf support for all modification modes.
- Unicode block character security score bar.
- Intelligent scoring excluding N/A and prerequisites.
- Comprehensive hardware detection (5 prerequisites).

### Fixed

- Restore mode warnings and hardware-only item filtering.
- PowerShell 5.1 compatibility issues (array handling, DateTime parsing).

## [2.0.0] - 2025-11-20

### Added

- Initial v2 release with modular function-based architecture.
- PowerShell 5.1 and 7.x compatibility.
- Runtime kernel detection via NtQuerySystemInformation.
- Interactive apply and restore modes.
- Automatic backup creation with JSON-based storage.