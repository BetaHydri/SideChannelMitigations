function Write-Log {
    <#
    .SYNOPSIS
        Writes a log entry to the session log file.

    .DESCRIPTION
        Appends a timestamped log entry with level indicator to the session log file.

    .PARAMETER Message
        The text message to write to the log file and optionally to the console.

    .PARAMETER Level
        The severity level of the log entry (Info, Success, Warning, Error, Debug).

    .PARAMETER NoConsole
        When specified, suppresses console output and only writes to the log file.

    .EXAMPLE
        Write-Log -Message "Assessment started" -Level Info

        Writes an informational log entry.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',

        [Parameter()]
        [switch]$NoConsole
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to log file
    try {
        Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        Write-Debug "Log write failed: $($_.Exception.Message)"
    }

    # Write to console (skip Debug messages unless $DebugPreference is set)
    if (-not $NoConsole) {
        # Skip Debug messages unless explicitly enabled
        if ($Level -eq 'Debug' -and $DebugPreference -eq 'SilentlyContinue') {
            return
        }

        $color = switch ($Level) {
            'Success' { 'Green' }
            'Warning' { 'Yellow' }
            'Error' { 'Red' }
            'Debug' { 'Gray' }
            default { 'Cyan' }
        }

        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}