function Invoke-IntuneBackupDeviceAssignmentFilter {
    <#
    .SYNOPSIS
    Backup Device Assignment Filters

    .DESCRIPTION
    Backup Intune Device Assignment Filters as JSON files per deployment profile to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .EXAMPLE
    Invoke-IntuneBackupDeviceAssignmentFilter -Path "C:\temp"
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
        Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }
	
    # Get all Autopilot Deployment Profiles
    $DeviceAssignmentFilters = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/assignmentFilters" -OutputType PSObject | Select-Object -ExpandProperty Value

    $global:DeviceFilters = $DeviceAssignmentFilters | Select-Object id, displayName

    if ($DeviceAssignmentFilters.value -ne "") {

  
        Write-Output "Backup - [Device Assignment Filters] - Count [$($DeviceAssignmentFilters.count)]"
        
        # Create folder if not exists
        if (-not (Test-Path "$Path\Device Assignment Filters")) {
            $null = New-Item -Path "$Path\Device Assignment Filters" -ItemType Directory
        }
	
        foreach ($DeviceAssignmentFilter in $DeviceAssignmentFilters) {
            $fileName = ($DeviceAssignmentFilter.id) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
	
            # Export the Deployment profile
            $DeviceAssignmentFilterObject = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/assignmentFilters/$($DeviceAssignmentFilter.id)"
            $DeviceAssignmentFilterObject | ConvertTo-Json -Depth 10 | Out-File -LiteralPath "$path\Device Assignment Filters\$fileName.json"
	
        }
    }
}
