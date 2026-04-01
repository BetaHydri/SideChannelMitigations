function Initialize-PlatformDetection {
    <#
    .SYNOPSIS
        Detects platform type and hardware capabilities.

    .DESCRIPTION
        Identifies whether the system is physical, a Hyper-V host, or a virtual
        machine guest, and populates CPU and OS details.

    .EXAMPLE
        Initialize-PlatformDetection

        Detects and stores platform type information.
    #>

    Write-Log -Message "Detecting platform type..." -Level Debug

    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $os = Get-CimInstance -ClassName Win32_OperatingSystem

    # Detect if virtual machine
    $isVM = $computerSystem.Model -match 'Virtual|VMware|Hyper-V'

    if ($isVM) {
        if ($computerSystem.Model -match 'VMware') {
            $script:PlatformInfo.Type = 'VMwareGuest'
            $script:PlatformInfo.Details['Hypervisor'] = 'VMware'
        }
        elseif ($computerSystem.Model -match 'Virtual|Hyper-V') {
            $script:PlatformInfo.Type = 'HyperVGuest'
            $script:PlatformInfo.Details['Hypervisor'] = 'Hyper-V'
        }
        else {
            $script:PlatformInfo.Type = 'VirtualMachine'
        }
    }
    else {
        # Check for Hyper-V role using multiple methods
        $isHyperVHost = $false

        # Method 1: Check Hyper-V service
        try {
            $hvService = Get-Service -Name vmms -ErrorAction SilentlyContinue
            if ($hvService -and $hvService.Status -eq 'Running') {
                $isHyperVHost = $true
            }
        }
        catch {
            Write-Debug "Hyper-V service check skipped: $($_.Exception.Message)"
        }

        # Method 2: Check for Hyper-V hypervisor
        if (-not $isHyperVHost) {
            try {
                $hypervisorPresent = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" -Name "HypervisorPresent" -ErrorAction SilentlyContinue
                if ($hypervisorPresent -and $hypervisorPresent.HypervisorPresent -eq 1) {
                    $isHyperVHost = $true
                }
            }
            catch {
                Write-Debug "Hypervisor registry check skipped: $($_.Exception.Message)"
            }
        }

        # Method 3: Check Win32_ComputerSystem HypervisorPresent
        if (-not $isHyperVHost) {
            try {
                if ($computerSystem.HypervisorPresent -eq $true) {
                    $isHyperVHost = $true
                }
            }
            catch {
                Write-Debug "ComputerSystem hypervisor check skipped: $($_.Exception.Message)"
            }
        }

        if ($isHyperVHost) {
            $script:PlatformInfo.Type = 'HyperVHost'
        }
        else {
            $script:PlatformInfo.Type = 'Physical'
        }
    }

    $script:PlatformInfo.Details['CPUVendor'] = $cpu.Manufacturer
    $script:PlatformInfo.Details['CPUModel'] = $cpu.Name
    $script:PlatformInfo.Details['OSVersion'] = $os.Caption
    $script:PlatformInfo.Details['OSBuild'] = $os.BuildNumber

    Write-Log -Message "Platform detected: $($script:PlatformInfo.Type)" -Level Info
}