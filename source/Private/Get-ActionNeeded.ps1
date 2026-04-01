function Get-ActionNeeded {
    <#
    .SYNOPSIS
        Determines the recommended action based on category and protection status.

    .DESCRIPTION
        Returns an action recommendation string based on the mitigation category (Critical, Recommended, Optional) and overall protection status.

    .PARAMETER Category
        The mitigation priority category (Critical, Recommended, or Optional).

    .PARAMETER OverallStatus
        The current protection status (Protected, Vulnerable, or Unknown).

    .EXAMPLE
        Get-ActionNeeded -Category "Critical" -OverallStatus "Vulnerable"

        Returns the action needed for a critical vulnerability.
    #>
    param(
        [string]$Category,
        [string]$OverallStatus
    )

    if ($OverallStatus -eq 'Protected') {
        return 'No'
    }

    switch ($Category) {
        'Critical' { return 'Yes - Critical' }
        'Recommended' { return 'Yes - Recommended' }
        'Optional' { return 'Consider' }
        default { return 'No' }
    }
}