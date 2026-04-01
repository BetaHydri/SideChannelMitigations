# Technical Context

## Tech Stack
- **Language**: PowerShell 5.1 / 7.x
- **Build Framework**: Sampler (ModuleBuilder + InvokeBuild + Pester 5 + GitVersion)
- **CI/CD**: Azure DevOps Pipelines
- **Testing**: Pester 5, Windows-only (requires registry access for integration tests)
- **Versioning**: GitVersion (ContinuousDelivery, `master` tag: `preview`, regex: `^main$`)

## Build Dependencies (RequiredModules.psd1)
- InvokeBuild, PSScriptAnalyzer, Pester, ModuleBuilder, ChangelogManagement, Sampler, Sampler.GitHubTasks

## Resolve-Dependency.psd1 Settings
- `UsePSResourceGet = $true`, `PSResourceGetVersion = '1.2.0'`
- `UsePowerShellGetCompatibilityModule = $true`, version `3.0.23-beta23`
- PSResourceGetVersion 1.0.1 has a `Requested value 'V2' was not found` bug - always use 1.2.0+

## Build Configuration (build.yaml)
- `Encoding: UTF8BOM` (critical for Pester on Azure DevOps)
- `BuiltModuleSubdirectory: module`
- `prefix: prefix.ps1` (module-scoped variables)
- `CodeCoverageThreshold: 0` (initial; increase as coverage improves)
- No DSC, no nested modules

## Pipeline Pattern
- **Build**: ubuntu-latest, GitVersion 5.x, `build.ps1 -ResolveDependency -tasks pack`
- **Test**: windows-latest, matrix (PS 5.1 + PS 7.x), NUnit results + JaCoCo coverage
- **Deploy_Preview**: condition `refs/heads/main` + `fam-tiedemann` org → `publish_module_to_gallery`
- **Deploy_Release**: condition `refs/tags/v*` + `fam-tiedemann` org → `publish` + `Create_ChangeLog_GitHub_PR`
- **Tag triggers**: include `v*`, exclude `*-*`
- **PR triggers**: include `source/*`

## Constraints
- Windows-only module (no Linux/macOS testing needed)
- Requires Admin privileges for registry access at runtime
- Tests use InModuleScope for private function testing
- All .ps1 files must be UTF-8 BOM encoded