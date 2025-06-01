function Invoke-IntuneBackupAutopilotDeploymentProfile {
    <#
    .SYNOPSIS
    Backup Intune Autopilot Deployment Profiles

    .DESCRIPTION
    Backup Intune Autopilot Deployment Profiles as JSON files per deployment profile to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .EXAMPLE
    Invoke-IntuneBackupAutopilotDeploymentProfile -Path "C:\temp"
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
    $winAutopilotDeploymentProfiles = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles" -OutputType PSObject | Select-Object -ExpandProperty Value

    if ($winAutopilotDeploymentProfiles.value -ne "") {

        [PSCustomObject]@{
            #"Action" = "Backup"
            "Type"   = "Autopilot Deployment Profile"
        }

        # Create folder if not exists
        if (-not (Test-Path "$Path\Autopilot Deployment Profiles")) {
            $null = New-Item -Path "$Path\Autopilot Deployment Profiles" -ItemType Directory
        }
	
        foreach ($winAutopilotDeploymentProfile in $winAutopilotDeploymentProfiles) {
            $fileName = ($winAutopilotDeploymentProfile.displayName) -replace '[^A-Za-z0-9-_ \.\[\]]', '' -replace ' ', '_'
	
            # Export the Deployment profile
            $winAutopilotDeploymentProfileObject = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/$($winAutopilotDeploymentProfile.id)"
            $winAutopilotDeploymentProfileObject | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Autopilot Deployment Profiles\$fileName.json"
	
		
        }
    }
}
