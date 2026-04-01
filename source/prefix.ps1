# Module-scoped variables - initialized on module import
$script:ModuleVersion = '0.0.1'

$script:BackupPath = Join-Path $PSScriptRoot 'Backups'
$script:ConfigPath = Join-Path $PSScriptRoot 'Config'
$script:LogPath = $null

# Runtime state storage
$script:RuntimeState = @{
    APIAvailable = $false
    Flags        = @{}
}

$script:PlatformInfo = @{
    Type    = 'Unknown'
    Details = @{}
}

$script:HardwareInfo = @{
    IsUEFI            = $false
    SecureBootEnabled = $false
    SecureBootCapable = $false
    TPMPresent        = $false
    TPMVersion        = 'Unknown'
    VTxEnabled        = $false
    IOMMUSupport      = $false
    VBSCapable        = $false
    HVCICapable       = $false
}