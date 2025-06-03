function Invoke-IntuneBackupDeviceCompliancePolicyAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Complaince Policy Assignments
    
    .DESCRIPTION
    Backup Intune Device Complaince Policy Assignments as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceCompliancePolicyAssignment -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All" 
    }

    # Get all Device Compliance Policies
    $deviceCompliancePolicies = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceCompliancePolicies" | Get-MgGraphAllPages

    if ($deviceCompliancePolicies.value -ne "") {

        Write-Output "Backup - [Device Compliance Policies Assignments]"

        # Create folder if not exists
        if (-not (Test-Path "$Path\Device Compliance Policies\Assignments")) {
            $null = New-Item -Path "$Path\Device Compliance Policies\Assignments" -ItemType Directory
        }
	
        foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
            $assignments = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceCompliancePolicies/$($deviceCompliancePolicy.id)/assignments" | Get-MgGraphAllPages
            if ($assignments) {
                $fileName = ($deviceCompliancePolicy.displayName) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
                $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Compliance Policies\Assignments\$fileName.json"

            }
        }
    }
}