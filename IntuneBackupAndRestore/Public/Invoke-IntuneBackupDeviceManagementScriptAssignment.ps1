function Invoke-IntuneBackupDeviceManagementScriptAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Management Script Assignments
    
    .DESCRIPTION
    Backup Intune Device Management Script Assignments as JSON files per Device Management Script to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceManagementScriptAssignment -Path "C:\temp"
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
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all assignments from all policies
    $deviceManagementScripts = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceManagementScripts" | Get-MgGraphAllPages

	if ($deviceManagementScripts.value -ne "") {

        Write-Output "Backup - [Device Management Script Assignments] - Count [$($deviceManagementScripts.count)]"

		# Create folder if not exists
		if (-not (Test-Path "$Path\Device Management Scripts\Assignments")) {
			$null = New-Item -Path "$Path\Device Management Scripts\Assignments" -ItemType Directory
		}

		foreach ($deviceManagementScript in $deviceManagementScripts) {
			$assignments = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceManagementScripts/$($deviceManagementScript.id)/assignments" | Get-MgGraphAllPages
	
			if ($assignments) {
				$fileName = ($deviceManagementScript.displayName) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
				$assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Management Scripts\Assignments\$fileName.json"
	

			}
		}
	}
}