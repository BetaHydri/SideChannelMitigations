function Initialize-Log {
    <#
    .SYNOPSIS
        Initializes the session log file with a header.

    .DESCRIPTION
        Creates or overwrites the log file with session metadata including version, user, computer, and PowerShell version.

    .EXAMPLE
        Initialize-Log

        Creates the session log file.
    #>
    $header = @"
================================================================================
Side-Channel Vulnerability Mitigation Tool - Version $script:ModuleVersion
Session Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
User: $env:USERNAME
Computer: $env:COMPUTERNAME
PowerShell Version: $($PSVersionTable.PSVersion)
================================================================================

"@
    try {
        Set-Content -Path $script:LogPath -Value $header -Encoding UTF8 -Force
    }
    catch {
        Write-Warning "Could not initialize log file: $($_.Exception.Message)"
    }
}