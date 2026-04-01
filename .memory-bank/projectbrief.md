# Project Brief

## Purpose
Enterprise-grade PowerShell module for assessing and managing Windows side-channel vulnerability mitigations (Spectre, Meltdown, L1TF, MDS, and related CVEs).

## Key Goals
- Evaluate 20+ side-channel mitigations with runtime kernel-level detection
- Assess 5 hardware security prerequisites (UEFI, Secure Boot, TPM 2.0, VT-x, IOMMU)
- Platform-aware intelligence (Physical, Hyper-V Host/Guest, VMware Guest)
- Interactive apply/revert with automatic backup/restore
- PowerShell 5.1 and 7.x compatible (Windows only)

## Scope
- Windows 10/11, Windows Server 2016+
- Requires Administrator privileges
- Registry-based mitigation management
- CSV export for compliance reporting