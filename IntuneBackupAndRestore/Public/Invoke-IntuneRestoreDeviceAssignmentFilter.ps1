function Invoke-IntuneRestoreDeviceAssignmentFilter {
    <#
    .SYNOPSIS
    Restore Intune Device Assignment Filters
    
    .DESCRIPTION
    Restore Intune Device Assignment Filters from JSON files per Deployment Profile from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceAssignmentFilter function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceAssignmentFilter -Path "C:\temp"
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
    if($null -eq (Get-MgContext)){
        Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all device health scripts
    $DeviceAssignmentFilters = Get-ChildItem -Path "$Path\Device Assignment Filters" -File -ErrorAction SilentlyContinue
	
    foreach ($DeviceAssignmentFilter in $DeviceAssignmentFilters) {
        $DeviceAssignmentFilterContent = Get-Content -LiteralPath $DeviceAssignmentFilter.FullName -Raw
        $DeviceAssignmentFilterDisplayName = ($DeviceAssignmentFilterContent | ConvertFrom-Json).displayName  
        
        # Remove properties that are not available for creating a new filter
        $requestBodyObject = $DeviceAssignmentFilterContent | ConvertFrom-Json
        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime | ConvertTo-Json

        # Restore the Deployment Profile
		try {
			$null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri "$ApiVersion/deviceManagement/assignmentFilters" -ErrorAction Stop
			[PSCustomObject]@{
				"Action" = "Restore"
				"Type"   = "Device Assignment Filter"
				"Name"   = $DeviceAssignmentFilterDisplayName
			}
		}
		catch {
			Write-Verbose "$DeviceAssignmentFilterDisplayName - Failed to restore Device Assignment Filter" -Verbose
			Write-Error $_ -ErrorAction Continue
		}
    }
}