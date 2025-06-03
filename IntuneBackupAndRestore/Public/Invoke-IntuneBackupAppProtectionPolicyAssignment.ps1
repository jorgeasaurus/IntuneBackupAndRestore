function Invoke-IntuneBackupAppProtectionPolicyAssignment {
	<#
    .SYNOPSIS
    Backup Intune App Protection Policy Assignments
    
    .DESCRIPTION
    Backup Intune App Protection Policy Assignments as JSON files per App Protection Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupAppProtectionPolicyAssignment -Path "C:\temp"
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

	$appProtectionPolicies = Invoke-MgGraphRequest -Uri "/$ApiVersion/deviceAppManagement/managedAppPolicies" | Get-MgGraphAllPages

	if ($appProtectionPolicies.value -ne "") {

		Write-Output "Backup - [App Protection Policy Assignments]"


		# Create folder if not exists
		if (-not (Test-Path "$Path\App Protection Policies\Assignments")) {
			$null = New-Item -Path "$Path\App Protection Policies\Assignments" -ItemType Directory
		}
	
		foreach ($appProtectionPolicy in $appProtectionPolicies) {
			switch ($appProtectionPolicy.'@odata.type') {
				"#microsoft.graph.androidManagedAppProtection" {
					$dataType = "androidManagedAppProtections"
					break
				}
				"#microsoft.graph.iosManagedAppProtection" {
					$dataType = "iosManagedAppProtections"
					break
				}
				"#microsoft.graph.mdmWindowsInformationProtectionPolicy" {
					$dataType = "mdmWindowsInformationProtectionPolicies"
					break
				}
				"#microsoft.graph.windowsInformationProtectionPolicy" {
					$dataType = "windowsInformationProtectionPolicies"
					break
				}
				"#microsoft.graph.targetedManagedAppConfiguration" {
					$dataType = "targetedManagedAppConfigurations"
					break
				}
				Default {
					continue
				}
			}
			$assignments = Invoke-MgGraphRequest -Uri "/$ApiVersion/deviceAppManagement/$dataType('$($appProtectionPolicy.id)')/assignments"
	
			$fileName = ($appProtectionPolicy.displayName) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
			$assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\Assignments\$fileName.json"
		}
	}
}
