# AGENTS.md - JEnv for Windows

## Project Type
PowerShell-based Java version manager for Windows 10+. Written in cmd/PowerShell.

## Directory Structure
```
src/
  jenv.ps1          # Main entry point
  util.psm1         # Shared utilities (Open-Prompt, Get-JavaVersion)
  jenv-*.psm1       # Command modules (add, remove, change, use, local, list, link, getjava, uninstall, autoscan)
tests/
  test.ps1          # Pester tests
  Fake-Executables/ # Mock Java installations for testing
jenv.bat            # CMD wrapper (calls jenv.ps1 via pwsh/powershell)
java.bat            # Dummy java launcher (placed in PATH by jenv)
```

## Build/Test Commands
```powershell
# Install Pester (required for tests)
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run tests (REQUIRES pwsh = PowerShell 7+, NOT Windows PowerShell 5.1)
pwsh tests/test.ps1

# Lint PowerShell
Import-Module PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path src -Settings PSScriptAnalyzerSettings.psd1
```

## Critical Testing Requirements
- Tests REQUIRE administrator privileges (`#Requires -RunAsAdministrator` in test.ps1)
- Tests REQUIRE `pwsh` (PowerShell 7+) - old Pester in Windows PowerShell 5.1 cannot be updated
- Tests backup/restore env vars and JEnv config automatically
- **Tests MUST complete fully** - if interrupted, your env vars and config will NOT be restored
- Tests modify `HKLM:\...\Machine` PATH and user PATH

## Config Location
`$Env:APPDATA\JEnv\jenv.config.json`
- `jenvs[]` - registered Java installations (name + path)
- `locals[]` - per-directory Java preferences (path + name)
- `global` - global Java version name

## Performance Optimization

### Java Call Caching (Critical for Speed)
- `java.bat` uses a cache file (`jenv.java.cache`) to avoid PowerShell startup on every `java` call
- Cache is updated by `jenv getjava`, `jenv use`, `jenv change`, `jenv local`
- Without caching: ~11 seconds per `java` call (PowerShell startup dominates)
- With caching: ~300ms per `java` call (35x improvement)

### PowerShell Startup Optimization
- `jenv.bat` uses `-NoProfile` flag to skip profile script loading
- This saves ~200-500ms per PowerShell invocation

### Parent Directory Traversal
- `jenv-getjava.psm1` uses `(Get-Location).ProviderPath` + `Split-Path` instead of `.Parent`
- `.Parent` can return null in some PowerShell contexts, breaking inheritance

## Version Management
Version is hardcoded in `src/jenv.ps1`: `$JENV_VERSION = "v2.2.1"`

Release workflow (`.github/workflows/release.yml`):
1. Tag push triggers release
2. `jacobtomlinson/gha-find-replace` action injects `${GITHUB_REF#refs/*/}` into `JENV_VERSION`
3. Zips `src/`, `jenv.bat`, `java.bat` as `JEnv.zip`

## Architecture Notes
- `jenv.bat` checks for `pwsh` first, falls back to `powershell`
- JEnv prepends itself to PATH to intercept `java` calls
- Session-level changes via `--output` flag write to `jenv.path.tmp`, `jenv.home.tmp`
- Batch file reads these tmp files and sets env vars for the current CMD session
- PowerShell module structure: each command is a separate `.psm1` file with an `Invoke-*` function

## Deployment Notes
When deploying changes to a live installation (e.g., `D:\Program Files\Java\JEnv`):
- Copy modified files: `jenv.bat`, `java.bat`, `src\*.psm1`
- Clear `jenv.java.cache` to force re-resolution
- If `JENVUSE` environment variable is set, `java.bat` uses it directly (session override)

## Code Style
- PSScriptAnalyzerSettings.psd1 excludes `PSAvoidUsingWriteHost` (allow Write-Host)
- Module exports not used - functions called directly by name after Import-Module
