# Product Context

## Why This Exists
System administrators need a reliable, automated way to check whether their Windows systems have proper side-channel vulnerability mitigations enabled. Microsoft provides the SpeculationControl module but it only covers CPU mitigations. This module extends coverage to include VBS, HVCI, Credential Guard, hardware prerequisites, and provides actionable remediation with backup/restore safety.

## Target Users
- Windows system administrators
- Security teams and auditors
- Hyper-V and VMware administrators
- Enterprise IT managing fleet-wide baselines

## UX Goals
- Single command to assess entire system: `Invoke-SideChannelAssessment`
- Color-coded output with visual progress bar
- Platform-aware (only scores applicable mitigations)
- Safe remediation with automatic backups
- Export for compliance reporting