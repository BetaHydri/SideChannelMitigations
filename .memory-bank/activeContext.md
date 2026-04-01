# Active Context

## Current State
Module conversion complete. Build + Tests pass (0.2.0-preview0001, 14 tasks, 0 errors, 284 tests, 0 failures).

## Recent Changes (2026-04-01)
- Extracted 30 functions from monolithic script into Sampler module structure
- 5 public functions, 26 private functions
- Fixed test path: `$PSScriptRoot\..\..` → `$PSScriptRoot\..\..\..` in all 11 unit test files
- Added comment-based help (SYNOPSIS, DESCRIPTION, PARAMETER, EXAMPLE) to all 31 source files
- Fixed all PSScriptAnalyzer violations: trailing whitespace, empty catch blocks, positional params, unused vars
- Created `.ScriptAnalyzerSettings.psd1` excluding PSAvoidUsingWriteHost, PSAvoidOverwritingBuiltInCmdlets, PSUseBOMForUnicodeEncodedFile, PSAvoidUsingWMICmdlet
- Created 20 stub test files for private functions
- Fixed SuppressMessageAttribute placement (must come after CBH, before param)
- All source files UTF-8 BOM encoded

## Next Steps
- [ ] Increase CodeCoverageThreshold from 0
- [ ] Write real unit tests for stub test files (currently skipped)
- [ ] Archive `SideChannel_Check_v2.ps1`
- [ ] Update README for module usage