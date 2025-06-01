function Invoke-IntuneBackupDeviceHealthScript {
	<#
    .SYNOPSIS
    Backup Intune Health Scripts (Remediation scripts)

    .DESCRIPTION
    Backup Intune Health Scripts (Remediation scripts) as JSON files per Health Script to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .EXAMPLE
    Invoke-IntuneBackupDeviceHealthScript -Path "C:\temp"
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

	# Get all Intune Health Scripts
	$healthScripts = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts" | Get-MGGraphAllPages

	if ($healthScripts.value -ne "") {

		[PSCustomObject]@{
			#"Action" = "Backup"
			"Type"   = "Device Health Scripts"
			#"Path"   = "Device Health Scripts\$fileName.json"
		}

		# Create folder if not exists
		if (-not (Test-Path "$Path\Device Health Scripts")) {
			$null = New-Item -Path "$Path\Device Health Scripts" -ItemType Directory
		}
	
		foreach ($healthScript in $healthScripts) {
			$fileName = ($healthScript.displayName) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
	
			# Export the Health script profile (excluding Microsoft builtin scripts)
			if (-not ($healthScript.publisher -eq "Microsoft")) {
				$healthScriptObject = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts/$($healthScript.id)"
				$healthScriptObject | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Device Health Scripts\$fileName.json"
	
				# Create folder if not exists
				if (-not (Test-Path "$Path\Device Health Scripts\Script Content")) {
					$null = New-Item -Path "$Path\Device Health Scripts\Script Content" -ItemType Directory
				}
	
				$healthScriptObject = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts/$($healthScript.id)"
				$healthScriptDetectionContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($healthScriptObject.detectionScriptContent))
				$healthScriptDetectionContent | Out-File -LiteralPath "$path\Device Health Scripts\Script Content\$fileName`_detection.ps1"
				$healthScriptRemediationContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($healthScriptObject.remediationScriptContent))
				$healthScriptRemediationContent | Out-File -LiteralPath "$path\Device Health Scripts\Script Content\$fileName`_remediation.ps1"
	

			}
		}
	}
}
