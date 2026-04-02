# Quick Start Guide

> Applies to **SideChannelMitigations** module v3.x
> (Sampler-based PowerShell module).
> For the legacy standalone script see `legacy/SideChannel_Check_v2.ps1`.

---

## Getting started

### Prerequisites

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or 7.x
- Administrator privileges

### Installation

```powershell
# Install from PSGallery (preview)
Install-Module -Name SideChannelMitigations -AllowPrerelease `
    -Scope CurrentUser

# Import the module
Import-Module SideChannelMitigations
```

**Or build from source:**

```powershell
git clone https://github.com/BetaHydri/SideChannelMitigations.git
Set-Location SideChannelMitigations
.\build.ps1
Import-Module ./output/module/SideChannelMitigations
```

### Basic assessment (default)

```powershell
# Run assessment and display current mitigation status
Invoke-SideChannelAssessment
```

### Detailed educational view

```powershell
# Show CVEs, descriptions, impacts, and recommendations
Invoke-SideChannelAssessment -ShowDetails
```

---

## Understanding color coding

The tool uses intelligent color coding based on **mitigation category**
and **severity**:

- **Green** = Protected/Active (working correctly)
- **Red** = Critical vulnerability (immediate action required)
- **Yellow** = Optional/Consider (evaluate for your environment)
- **Gray** = Informational (prerequisites, hardware status)

**Categories:**

- **Critical** -> Red when vulnerable
  (SSBD, BTI, KVAS, SBDR, PSDP)
- **Recommended** -> Red when vulnerable
  (MDS, TSX Disable, SRBDS, Retbleed)
- **Optional** -> Yellow when not enabled
  (L1TF, Hyper-V Core Scheduler, Disable SMT)
- **Prerequisite** -> Gray
  (UEFI, Secure Boot, TPM, VT-x/ARM VHE, IOMMU/SMMU)

---

## Available modes

### 1. **Assess** (default)

Evaluate security posture without making changes.

```powershell
# Standard assessment
Invoke-SideChannelAssessment

# With detailed educational output
Invoke-SideChannelAssessment -ShowDetails

# Export to CSV
Invoke-SideChannelAssessment -ExportPath 'C:\Reports'
```

---

### 2. **ApplyInteractive**

Selectively apply mitigations with two view modes.

```powershell
# Preview changes first (recommended)
Invoke-SideChannelAssessment -Mode ApplyInteractive -WhatIf

# Interactive application
Invoke-SideChannelAssessment -Mode ApplyInteractive
```

**Selection modes:**

- **[R] Recommended** - shows only actionable mitigations
  (quick hardening)
- **[A] All Mitigations** - shows all mitigations
  (selective hardening after review)

**Recommended workflow:**

1. `Invoke-SideChannelAssessment -ShowDetails` -
   review CVEs and impacts
2. `Invoke-SideChannelAssessment -Mode Backup` -
   create manual backup (recommended before remediation)
3. `Invoke-SideChannelAssessment -Mode ApplyInteractive` -
   choose [A] mode
4. Select specific mitigations based on your requirements
5. Restart system to activate changes
6. If needed, restore:
   `Invoke-SideChannelAssessment -Mode Revert` or
   `-Mode RestoreInteractive`

---

### 3. **Revert**

**Quick undo:** Instantly revert to your most recent backup.

```powershell
# Preview revert
Invoke-SideChannelAssessment -Mode Revert -WhatIf

# Revert to latest backup
Invoke-SideChannelAssessment -Mode Revert
```

**When to use:**

- You just applied changes and want to undo them quickly
- System is unstable after applying mitigations
- Simple one-step rollback to last known good state

**What it does:** Automatically finds and restores your most
recent backup (complete restore only).

---

### 4. **Backup**

**Manual snapshot:** Create a backup before making changes or
for safekeeping.

```powershell
# Preview backup
Invoke-SideChannelAssessment -Mode Backup -WhatIf

# Create backup
Invoke-SideChannelAssessment -Mode Backup
```

**When to use:**

- Before testing changes in production
- Creating a checkpoint before major configuration updates
- Scheduled backups for compliance/audit purposes

> **Note:** ApplyInteractive mode **automatically creates a
> selective backup** of the mitigations you chose to apply, so
> manual backup is optional. Use `-Mode Backup` to create a
> full backup of all mitigations.

---

### 5. **RestoreInteractive**

**Advanced recovery:** Browse all backups and choose what to
restore (selective or complete).

```powershell
# Interactive restore
Invoke-SideChannelAssessment -Mode RestoreInteractive
```

**When to use:**

- Need to restore from an older backup (not just the latest)
- Want to restore only specific mitigations, not everything
- Comparing multiple backups before deciding which to restore
- Recovering from older configuration states

**Restore options:**

- **[A] All** - restore complete backup (all settings)
- **[S] Select** - choose individual mitigations to restore
  (granular recovery)
- **[Q] Cancel** - exit without changes

**Difference from Revert:**

- **Revert** = quick undo to latest backup
  (one command, no choices)
- **RestoreInteractive** = browse all backups, choose which
  one, choose what to restore (flexible)

---

## Mode comparison quick reference

| Mode | Purpose | Backup Selection | Restore Options | Use Case |
|------|---------|------------------|-----------------|----------|
| **Revert** | Quick undo | Latest only (automatic) | Complete only | "Oops, undo that!" |
| **RestoreInteractive** | Advanced recovery | Choose any backup | Complete or Selective | "I need that setting from 3 days ago" |
| **Backup** | Create snapshot | N/A | N/A | "Checkpoint before changes" |
| **ApplyInteractive** | Apply mitigations | Auto-creates selective backup | N/A | "Harden my system" |

**Decision tree:**

- Need to **undo recent changes**? -> Use **Revert** (fastest)
- Need **older backup** or **specific settings**? ->
  Use **RestoreInteractive** (flexible)
- About to **test something risky**? ->
  Use **Backup** first (safety net)
- Want to **harden system**? ->
  Use **ApplyInteractive** (auto-backup included)

---

## Common workflows

### Quick security audit

```powershell
# Assess and export report
Invoke-SideChannelAssessment -ExportPath 'C:\Reports'
```

### Safe hardening (recommended)

```powershell
# Step 1: Review what needs fixing
Invoke-SideChannelAssessment -ShowDetails

# Step 2: Preview what will change
Invoke-SideChannelAssessment -Mode ApplyInteractive -WhatIf

# Step 3: Apply changes (automatic backup created)
Invoke-SideChannelAssessment -Mode ApplyInteractive

# Step 4 (if problems): Quick undo
Invoke-SideChannelAssessment -Mode Revert
```

### Manual backup before changes

```powershell
# Create full checkpoint first
Invoke-SideChannelAssessment -Mode Backup

# Apply changes (creates another selective backup automatically)
Invoke-SideChannelAssessment -Mode ApplyInteractive

# If needed: Restore from specific backup
Invoke-SideChannelAssessment -Mode RestoreInteractive
```

### Selective recovery

```powershell
# Browse all backups and restore only specific mitigations
Invoke-SideChannelAssessment -Mode RestoreInteractive
# Choose backup, then select [S] for selective restore
```

### Standalone cmdlet usage

```powershell
# Get all mitigation definitions
Get-SideChannelMitigationDefinition

# Filter critical mitigations
Get-SideChannelMitigationDefinition |
    Where-Object { $_.Category -eq 'Critical' }

# Create a backup directly
New-SideChannelBackup -Mitigations (Get-SideChannelMitigationDefinition)

# Restore the latest backup directly (non-interactive)
Restore-SideChannelBackup -Latest
```

---

## Exported functions

| Function | Purpose |
|----------|---------|
| `Invoke-SideChannelAssessment` | Main orchestrator (assess, apply, backup, revert, restore) |
| `Export-SideChannelAssessment` | Export assessment results to CSV |
| `Get-SideChannelMitigationDefinition` | Return all mitigation definitions |
| `New-SideChannelBackup` | Create a timestamped JSON backup |
| `Restore-SideChannelBackup` | Restore settings from a backup file (non-interactive) |

---

## Parameter reference

| Parameter | Type | Description |
|-----------|------|-------------|
| `-Mode` | `string` | `Assess` (default), `ApplyInteractive`, `Revert`, `Backup`, `RestoreInteractive` |
| `-ShowDetails` | `switch` | Show CVEs, descriptions, impacts, recommendations |
| `-WhatIf` | `switch` | Preview changes without applying |
| `-ExportPath` | `string` | Destination **folder** for CSV export (filename auto-generated) |
| `-LogPath` | `string` | Destination **folder** for operation logs (filename auto-generated) |
| `-BackupPath` | `string` | Custom backup directory (default: module `Backups/` directory) |
| `-ConfigPath` | `string` | Custom configuration directory (default: module `Config/` directory) |

**CSV Export vs Log File:**

- **`-ExportPath`** -> assessment data
  (CSV with auto-generated filename in the specified folder)
- **`-LogPath`** -> execution log
  (troubleshooting/audit trail, filename auto-generated)
- For most users, only `-ExportPath` is needed

---

## Important notes

- **Always run as Administrator** - required for registry access
- **System restart required** - after applying mitigations
- **Use `-WhatIf` first** - preview changes safely before applying
- **Backups are automatic** - created before ApplyInteractive mode
- **Hardware-only items** - TPM, CPU Virtualization, IOMMU are
  auto-skipped in restore (firmware settings)

---

## Need help?

1. **Full documentation:** [README.md](README.md)
2. **GitHub Issues:**
   https://github.com/BetaHydri/SideChannelMitigations/issues
3. **Parameter help:**
   `Get-Help Invoke-SideChannelAssessment -Detailed`
