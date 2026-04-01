# Prompt History

## 2026-04-01
- **Convert monolithic script to Sampler module**: Extracted 30 functions, created 5 public / 26 private, set up build infrastructure, tests, pipeline, memory bank.
- **Reference projects used**: RC4-ADAssessment, Get-NtlmLogonEvents (for proven Sampler patterns).
- **Fix test failures**: Fixed path bug in 11 test files (`..\..\..`), added CBH to all 31 source files, fixed all PSSA violations (trailing whitespace, empty catch blocks, positional params, unused vars, plural nouns, ShouldProcess, OutputType), created 20 stub test files. Result: 192 failures → 0.