function Show-Header {
    <#
    .SYNOPSIS
        Displays the tool header banner.

    .DESCRIPTION
        Shows a formatted console header with tool name, version, and session information.

    .EXAMPLE
        Show-Header

        Displays the tool header.
    #>
    $header = @"

================================================================================
  Side-Channel Vulnerability Mitigation Tool - Version $script:ModuleVersion
================================================================================

"@
    Write-Host $header -ForegroundColor Cyan
}