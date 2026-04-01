function Get-StatusIcon {
    <#
    .SYNOPSIS
        Returns Unicode status icons for console display.

    .DESCRIPTION
        Returns Unicode character strings for status indicators. Compatible with PowerShell 5.1 and later.

    .PARAMETER Name
        The name of the status icon to return (e.g., Success, Error, Warning).

    .EXAMPLE
        Get-StatusIcon -Name "Success"

        Returns the checkmark Unicode character.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            'Success', 'Error', 'Warning', 'Info',
            'Check', 'Cross', 'Bullet',
            'RedCircle', 'YellowCircle', 'GreenCircle',
            'BlockFull', 'BlockLight'
        )]
        [string]$Name
    )

    switch ($Name) {
        'Success' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("2713", 16)) }  # ✓
        'Error' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("2717", 16)) }  # ✗
        'Warning' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("26A0", 16)) }  # $(Get-StatusIcon -Name Warning)
        'Info' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("2139", 16)) }  # ℹ
        'Check' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("2713", 16)) }  # ✓
        'Cross' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("2717", 16)) }  # ✗
        'Bullet' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("2022", 16)) }  # $(Get-StatusIcon -Name Bullet)
        'RedCircle' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("1F534", 16)) }  # $(Get-StatusIcon -Name RedCircle)
        'YellowCircle' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("1F7E1", 16)) }  # $(Get-StatusIcon -Name YellowCircle)
        'GreenCircle' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("1F7E2", 16)) }  # $(Get-StatusIcon -Name GreenCircle)
        'BlockFull' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("2588", 16)) }  # █
        'BlockLight' { [System.Char]::ConvertFromUtf32([System.Convert]::toInt32("2591", 16)) }  # ░
    }
}