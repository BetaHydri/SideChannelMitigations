# Quick Start Guide - v2.3.0

> **⚠️ BREAKING CHANGE in v2.3.0:** Modes renamed for clarity: `RevertInteractive` → `Revert`, `Restore` → `RestoreInteractive`. See README.md changelog for migration.
>
> **Note:** v2.3.0 adds intelligent microcode detection and upgrades SBDR/PSDP to Critical category. See README.md changelog for details.

---

## 🚀 Getting Started

### Basic Assessment (Default)
```powershell
# Run from repository root
.\SideChannel_Check_v2.ps1
```

### Detailed Educational View
```powershell
# Show CVEs, descriptions, impacts, and recommendations
.\SideChannel_Check_v2.ps1 -ShowDetails
```

---

## 📋 Available Modes

### 🎨 Understanding Color Coding

The tool uses intelligent color coding based on **mitigation category** and **severity**:

- 🟢 **Green** = Protected/Active (working correctly)
- 🔴 **Red** = Critical vulnerability (immediate action required)
- 🟡 **Yellow** = Optional/Consider (evaluate for your environment)
- ⚪ **Gray** = Informational (prerequisites, hardware status)

**Categories:**
- **Critical** → Red when vulnerable (SSBD, BTI, KVAS, SBDR, PSDP)
- **Recommended** → Red when vulnerable (MDS, TSX Disable, SRBDS, Retbleed)
- **Optional** → Yellow when not enabled (L1TF, Hyper-V Core Scheduler, Disable SMT)
- **Prerequisite** → Gray (UEFI, Secure Boot, TPM, VT-x, IOMMU)

**Examples:**
- **L1TF showing Yellow?** ✅ Correct - Optional, High performance impact, multi-tenant Hyper-V only
- **SBDR showing Red?** ✅ Correct - Critical vulnerability requiring immediate action
- **MDS showing Green?** ✅ Correct - CPU has hardware immunity

---

### 1️⃣ **Assess** (Default)
Evaluate security posture without making changes.

```powershell
# Standard assessment
.\SideChannel_Check_v2.ps1

# With detailed educational output
.\SideChannel_Check_v2.ps1 -ShowDetails

# Export to CSV
.\SideChannel_Check_v2.ps1 -ExportPath "C:\Reports"
```

---

### 2️⃣ **ApplyInteractive**
Selectively apply mitigations with two view modes.

```powershell
# Preview changes first (RECOMMENDED)
.\SideChannel_Check_v2.ps1 -Mode ApplyInteractive -WhatIf

# Interactive application
.\SideChannel_Check_v2.ps1 -Mode ApplyInteractive
```

**Selection Modes:**
- **[R] Recommended** - Shows only actionable mitigations (quick hardening)
- **[A] All Mitigations** - Shows all 30+ mitigations (selective hardening after review)

**Recommended Workflow:**
1. `.\SideChannel_Check_v2.ps1 -ShowDetails` - Review CVEs and impacts
2. `.\SideChannel_Check_v2.ps1 -Mode Backup` - Create manual backup (recommended before remediation)
3. `.\SideChannel_Check_v2.ps1 -Mode ApplyInteractive` - Choose [A] mode
4. Select specific mitigations based on your requirements
5. Restart system to activate changes
6. If needed, restore: `.\SideChannel_Check_v2.ps1 -Mode Revert` or `-Mode RestoreInteractive`

---

### 3️⃣ **Revert**
**Quick undo:** Instantly revert to your most recent backup.

```powershell
# Preview revert
.\SideChannel_Check_v2.ps1 -Mode Revert -WhatIf

# Revert to latest backup
.\SideChannel_Check_v2.ps1 -Mode Revert
```

**When to use:**
- ✅ You just applied changes and want to undo them quickly
- ✅ System is unstable after applying mitigations
- ✅ Simple one-step rollback to last known good state

**What it does:** Automatically finds and restores your most recent backup (complete restore only).

---

### 4️⃣ **Backup**
**Manual snapshot:** Create a backup before making changes or for safekeeping.

```powershell
# Preview backup
.\SideChannel_Check_v2.ps1 -Mode Backup -WhatIf

# Create backup
.\SideChannel_Check_v2.ps1 -Mode Backup
```

**When to use:**
- ✅ Before testing changes in production
- ✅ Creating a checkpoint before major configuration updates
- ✅ Scheduled backups for compliance/audit purposes

**Note:** ApplyInteractive mode **automatically creates a backup** before applying changes, so manual backup is optional in that workflow.

---

### 5️⃣ **RestoreInteractive**
**Advanced recovery:** Browse all backups and choose what to restore (selective or complete).

```powershell
# Interactive restore
.\SideChannel_Check_v2.ps1 -Mode RestoreInteractive
```

**When to use:**
- ✅ Need to restore from an older backup (not just the latest)
- ✅ Want to restore only specific mitigations, not everything
- ✅ Comparing multiple backups before deciding which to restore
- ✅ Recovering from older configuration states

**Restore Options:**
- **[A] All** - Restore complete backup (all settings)
- **[S] Select** - Choose individual mitigations to restore (granular recovery)
- **[Q] Cancel** - Exit without changes

**Difference from Revert:**
- **Revert** = Quick undo to latest backup (one command, no choices)
- **RestoreInteractive** = Browse all backups, choose which one, choose what to restore (flexible)

---

## 🔄 Mode Comparison Quick Reference

| Mode | Purpose | Backup Selection | Restore Options | Use Case |
|------|---------|------------------|-----------------|----------|
| **Revert** | Quick undo | Latest only (automatic) | Complete only | "Oops, undo that!" |
| **RestoreInteractive** | Advanced recovery | Choose any backup | Complete or Selective | "I need that setting from 3 days ago" |
| **Backup** | Create snapshot | N/A | N/A | "Checkpoint before changes" |
| **ApplyInteractive** | Apply mitigations | Auto-creates backup | N/A | "Harden my system" |

**Decision Tree:**
- Need to **undo recent changes**? → Use **Revert** (fastest)
- Need **older backup** or **specific settings**? → Use **RestoreInteractive** (flexible)
- About to **test something risky**? → Use **Backup** first (safety net)
- Want to **harden system**? → Use **ApplyInteractive** (auto-backup included)

---

## 🔧 Common Workflows

### Quick Security Audit
```powershell
# Assess and export report
.\SideChannel_Check_v2.ps1 -ExportPath "C:\Reports"
```

### Safe Hardening (Recommended)
```powershell
# Step 1: Review what needs fixing
.\SideChannel_Check_v2.ps1 -ShowDetails

# Step 2: Preview what will change
.\SideChannel_Check_v2.ps1 -Mode ApplyInteractive -WhatIf

# Step 3: Apply changes (automatic backup created)
.\SideChannel_Check_v2.ps1 -Mode ApplyInteractive

# Step 4 (if problems): Quick undo
.\SideChannel_Check_v2.ps1 -Mode Revert
```

### Manual Backup Before Changes
```powershell
# Optional: Create named checkpoint first
.\SideChannel_Check_v2.ps1 -Mode Backup

# Apply changes (creates another backup automatically)
.\SideChannel_Check_v2.ps1 -Mode ApplyInteractive

# If needed: Restore from specific backup
.\SideChannel_Check_v2.ps1 -Mode RestoreInteractive
```

### Selective Recovery
```powershell
# Browse all backups and restore only specific mitigations
.\SideChannel_Check_v2.ps1 -Mode RestoreInteractive
# Choose backup, then select [S] for selective restore
```

### Educational Review
```powershell
# Review all details with CVEs, impacts, recommendations
.\SideChannel_Check_v2.ps1 -ShowDetails

# Then apply selectively
.\SideChannel_Check_v2.ps1 -Mode ApplyInteractive
# Choose [A] for all mitigations view
```

---

## 📦 Legacy Version (Archived)

The original v1.x version is available in `archive/v1/` for reference:

```powershell
cd archive\v1
.\SideChannel_Check.ps1
```

**Note:** v1 is no longer actively maintained. Please use v2.3.0 for latest features and support.

---

## 💡 Key Features

- ✅ **5 Dedicated Modes** - Assess, ApplyInteractive, Revert, Backup, RestoreInteractive
- ✅ **Selective Apply & Restore** - Choose [R]ecommended/[A]ll or [A]ll/[S]elect options
- ✅ **WhatIf Support** - Preview all changes before applying
- ✅ **Educational View** - CVEs, descriptions, impacts, recommendations
- ✅ **Enhanced Runtime Status Guide** - 5 comprehensive states (Active, Inactive, Not Needed, Supported, N/A)
- ✅ **PowerShell 5.1 & 7.x** - Full compatibility with runtime Unicode generation
- ✅ **Hardware Detection** - UEFI, Secure Boot, TPM 2.0, VT-x, IOMMU
- ✅ **Intelligent Scoring** - Visual progress bar excludes N/A items

---

## ⚠️ Important Notes

- **Always run as Administrator** - Required for registry access
- **System restart required** - After applying mitigations
- **Use -WhatIf first** - Preview changes safely before applying
- **Backups are automatic** - Created before ApplyInteractive mode
- **Hardware-only items** - TPM, CPU Virtualization, IOMMU are auto-skipped in restore (firmware settings)

---

## 🆘 Need Help?

1. **Full Documentation:** [README.md](README.md)
2. **GitHub Issues:** https://github.com/BetaHydri/SideChannelMitigations/issues
3. **Parameter Help:** `Get-Help .\SideChannel_Check_v2.ps1 -Detailed`

---

## 📝 Parameter Reference

| Parameter | Values | Description |
|-----------|--------|-------------|
| `-Mode` | Assess, ApplyInteractive, Revert, Backup, RestoreInteractive | Operation mode (default: Assess) |
| `-ShowDetails` | Switch | Show CVEs, descriptions, impacts, recommendations |
| `-WhatIf` | Switch | Preview changes without applying |
| `-ExportPath` | Folder path | **Export assessment results** to CSV (filename auto-generated) |
| `-LogPath` | Path | Optional: Custom execution log location (default: `.\Logs\`) |

**CSV Export vs Log File:**
- **`-ExportPath`** → Your security assessment data (CSV with auto-generated filename in the specified folder)
- **`-LogPath`** → Execution log (troubleshooting/audit trail of what the script did)
- For most users, only `-ExportPath` is needed
